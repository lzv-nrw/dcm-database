CREATE TABLE migrations (
  from_version text UNIQUE,
  to_version text UNIQUE,
  completed_at text
);

-- all rows must only contain a single non-pk col
-- for example, do not combine schema_loaded with schema_version or
-- otherwise migrations might yield unexpected results
CREATE TABLE deployment (
  id uuid NOT NULL PRIMARY KEY,
  schema_loaded boolean,
  schema_version text,
  demo_loaded boolean,
  CONSTRAINT only_one_nullable CHECK (
    (CASE WHEN schema_loaded IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN schema_version IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN demo_loaded IS NOT NULL THEN 1 ELSE 0 END)
    = 1
  )
);

-- Add unique constraint to reject duplicates of deployment table values
CREATE UNIQUE INDEX only_one_schema_version ON deployment ((1)) WHERE schema_version IS NOT NULL;

CREATE TABLE user_configs (
  id uuid NOT NULL PRIMARY KEY,
  external_id text,
  status text,
  username text UNIQUE,
  firstname text,
  lastname text,
  email text,
  widget_config jsonb,
  user_created uuid REFERENCES user_configs (id) ON DELETE SET NULL,
  user_modified uuid REFERENCES user_configs (id) ON DELETE SET NULL,
  datetime_created text,
  datetime_modified text
);

CREATE TABLE workspaces (
  id uuid NOT NULL PRIMARY KEY,
  name text UNIQUE NOT NULL,
  user_created uuid REFERENCES user_configs (id) ON DELETE SET NULL,
  user_modified uuid REFERENCES user_configs (id) ON DELETE SET NULL,
  datetime_created text,
  datetime_modified text
);

CREATE TABLE templates (
  id uuid NOT NULL PRIMARY KEY,
  status text,
  workspace_id uuid REFERENCES workspaces (id) ON DELETE SET NULL,
  name text,
  description text,
  type text,
  additional_information jsonb,
  target_archive jsonb,
  user_created uuid REFERENCES user_configs (id) ON DELETE SET NULL,
  user_modified uuid REFERENCES user_configs (id) ON DELETE SET NULL,
  datetime_created text,
  datetime_modified text
);

CREATE TABLE user_secrets (
  id uuid NOT NULL PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES user_configs (id) ON DELETE CASCADE,
  password text NOT NULL
);

-- Auxiliary table to define many-to-many relationships
-- between groups, users and workspaces
CREATE TABLE user_groups (
  id uuid NOT NULL PRIMARY KEY,
  group_id text NOT NULL,
  user_id uuid NOT NULL REFERENCES user_configs (id) ON DELETE CASCADE,
  workspace_id uuid REFERENCES workspaces (id) ON DELETE CASCADE,
  UNIQUE (group_id, user_id, workspace_id)
);

-- Add unique constraint to reject duplicates of (user_id, group_id) when workspace_id is NULL
CREATE UNIQUE INDEX user_groups_no_workspace
ON user_groups (user_id, group_id)
WHERE workspace_id is NULL;

-- latest_exec corresponds to token field of jobs-table
-- (omit reference for now to keep sqlite-compatibility, not needed anyway)
CREATE TABLE job_configs (
  id uuid NOT NULL PRIMARY KEY,
  status text,
  template_id uuid NOT NULL REFERENCES templates (id) ON DELETE CASCADE,
  latest_exec uuid,
  name text,
  description text,
  contact_info text,
  user_created uuid REFERENCES user_configs (id) ON DELETE SET NULL,
  user_modified uuid REFERENCES user_configs (id) ON DELETE SET NULL,
  datetime_created text,
  datetime_modified text,
  data_selection jsonb,
  data_processing jsonb,
  schedule jsonb
);

CREATE TABLE jobs (
  token uuid NOT NULL PRIMARY KEY,
  status text,
  job_config_id uuid REFERENCES job_configs (id) ON DELETE SET NULL,
  user_triggered uuid REFERENCES user_configs (id) ON DELETE SET NULL,
  datetime_triggered text,
  trigger_type text,
  datetime_artifacts_expire text,
  success boolean,
  datetime_started text,
  datetime_ended text,
  report jsonb
);

-- see comment before job_configs-table
-- ALTER TABLE job_configs ADD FOREIGN KEY (latest_exec) REFERENCES jobs(token);

CREATE TABLE ies (
    id uuid NOT NULL PRIMARY KEY,
    job_config_id uuid NOT NULL REFERENCES job_configs (id) ON DELETE CASCADE,
    source_organization text, -- human readable name of source organization
    origin_system_id text NOT NULL, -- source system identifier
    external_id text NOT NULL, -- unique identifier within source system
    archive_id text NOT NULL, -- target archive identifier
    CONSTRAINT unique_ids UNIQUE (
      job_config_id,
      origin_system_id,
      external_id,
      archive_id
    )
);

CREATE TABLE records ( -- processing-iterations of an IE
    id uuid NOT NULL PRIMARY KEY,
    job_config_id uuid NOT NULL REFERENCES job_configs (id) ON DELETE CASCADE,
    job_token uuid NOT NULL REFERENCES jobs (token),
    ie_id uuid REFERENCES ies (id), -- set as soon as identification is possible
    status text CHECK(
      status IN (
        'in-process',
        'complete',
        'process-error',
        'import-error',
        'obj-val-error',
        'ip-val-error',
        'build-ip-error',
        'prepare-ip-error',
        'build-sip-error',
        'transfer-error',
        'ingest-error'
      )
    ),
    datetime_changed text, -- used to identify latest record for given ie
    -- additional flags that applied during processing
    ignored boolean, -- whether this record is ignored (for the current revision in source system)
    bitstream boolean, -- whether the record was processed as bitstream
    skip_object_validation boolean, -- whether object validation was skipped for this record
    -- record-specific identifiers
    import_type text CHECK( import_type IN ( 'oai', 'hotfolder' ) ),
    oai_identifier text, -- as reported by Import Module
    oai_datestamp text, -- as reported by Import Module
    hotfolder_original_path text, -- as reported by Import Module
    archive_ie_id text, -- as reported by the archive system
    archive_sip_id text -- as reported by the archive system
);

-- view that combines ies with info from latest record
CREATE VIEW ies_with_latest_record AS
SELECT
    ies.*,
    records.id AS latest_record_id,
    records.job_token AS latest_record_job_token,
    records.status AS latest_record_status,
    records.datetime_changed AS latest_record_datetime_changed,
    records.ignored AS latest_record_ignored,
    records.bitstream AS latest_record_bitstream,
    records.skip_object_validation AS latest_record_skip_object_validation,
    records.import_type AS latest_record_import_type,
    records.oai_identifier AS latest_record_oai_identifier,
    records.oai_datestamp AS latest_record_oai_datestamp,
    records.hotfolder_original_path AS latest_record_hotfolder_original_path,
    records.archive_ie_id AS latest_record_archive_ie_id,
    records.archive_sip_id AS latest_record_archive_sip_id
FROM ies
LEFT JOIN records
    ON records.id = (
        SELECT id FROM records
        WHERE ie_id = ies.id
        ORDER BY datetime_changed DESC NULLS LAST
        LIMIT 1
    );

-- all IEs should only ever be in-process once at a given time
CREATE UNIQUE INDEX unique_ie_in_process
ON records (job_config_id, ie_id)
WHERE ie_id IS NOT NULL AND status = 'in-process';

CREATE TABLE artifacts (
  id uuid NOT NULL PRIMARY KEY,
  path text NOT NULL,
  datetime_expires text,
  record_id uuid REFERENCES records (id), -- associated record
  stage text CHECK(
    stage IN (
      'import_ies',
      'import_ips',
      'build_ip',
      'prepare_ip',
      'build_sip'
    )
  ) -- associated processing step
);
