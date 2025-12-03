BEGIN TRANSACTION;

-- create new artifacts-table
CREATE TABLE artifacts (
  id uuid NOT NULL PRIMARY KEY,
  path text NOT NULL,
  datetime_expires text,
  record_id uuid REFERENCES records (id),
  stage text CHECK(
    stage IN (
      'import_ies',
      'import_ips',
      'build_ip',
      'prepare_ip',
      'build_sip'
    )
  )
);

-- [ies, records] replace original records table with new tables and constraints
-- earlier versions of the records-table are not compatible
DROP TABLE records;
CREATE TABLE ies (
    id uuid NOT NULL PRIMARY KEY,
    job_config_id uuid NOT NULL REFERENCES job_configs (id) ON DELETE CASCADE,
    source_organization text,
    origin_system_id text NOT NULL,
    external_id text NOT NULL,
    archive_id text NOT NULL,
    CONSTRAINT unique_ids UNIQUE (
      job_config_id,
      origin_system_id,
      external_id,
      archive_id
    )
);
CREATE TABLE records (
    id uuid NOT NULL PRIMARY KEY,
    job_config_id uuid NOT NULL REFERENCES job_configs (id) ON DELETE CASCADE,
    job_token uuid NOT NULL REFERENCES jobs (token),
    ie_id uuid REFERENCES ies (id),
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
    datetime_changed text,
    ignored boolean,
    bitstream boolean,
    skip_object_validation boolean,
    import_type text CHECK( import_type IN ( 'oai', 'hotfolder' ) ),
    oai_identifier text,
    oai_datestamp text,
    hotfolder_original_path text,
    archive_ie_id text,
    archive_sip_id text
);

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

CREATE UNIQUE INDEX unique_ie_in_process
ON records (job_config_id, ie_id)
WHERE ie_id IS NOT NULL AND status = 'in-process';

-- [jobs] add column 'datetime_artifacts_expire'
ALTER TABLE jobs ADD datetime_artifacts_expire text;

INSERT INTO migrations (from_version, to_version, completed_at) VALUES ('2.1.0', '3.0.0', current_timestamp);
UPDATE deployment SET schema_version = '3.0.0' WHERE schema_version = '2.1.0';
COMMIT;
