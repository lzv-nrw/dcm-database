BEGIN TRANSACTION;

-- job execution lock
CREATE UNIQUE INDEX unique_job_execution_per_config
ON jobs (job_config_id)
WHERE job_config_id IS NOT NULL AND (status = 'queued' OR status = 'running');

-- [ies_with_latest_record] drop view
DROP VIEW IF EXISTS ies_with_latest_record;

-- [records] add column 'baginfo_metadata'
ALTER TABLE records ADD baginfo_metadata jsonb;

-- [ies_with_latest_record] recreate view including 'records.baginfo_metadata'
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
    records.archive_sip_id AS latest_record_archive_sip_id,
    records.baginfo_metadata AS latest_record_baginfo_metadata
FROM ies
LEFT JOIN records
    ON records.id = (
        SELECT id FROM records
        WHERE ie_id = ies.id
        ORDER BY datetime_changed DESC NULLS LAST
        LIMIT 1
    );

-- [records] add ON DELETE action when deleting a row from ies
-- get name of foreign key constraint for field 'records.ie_id'
SELECT con.conname AS constraint_name
FROM pg_constraint AS con
JOIN pg_class tbl ON tbl.oid = con.conrelid
JOIN LATERAL unnest(con.conkey) AS colnum(attnum) ON TRUE
JOIN pg_attribute attr ON attr.attrelid = tbl.oid AND attr.attnum = colnum.attnum
WHERE con.contype = 'f'
  AND tbl.relname = 'records'
  AND attr.attname = 'ie_id';
-- drop existing constraint (assuming the name of foreign key constraint is 'records_ie_id_fkey')
ALTER TABLE records
DROP CONSTRAINT records_ie_id_fkey;
-- add a new constraint with ON DELETE action
ALTER TABLE records
ADD CONSTRAINT records_ie_id_fkey
FOREIGN KEY (ie_id)
REFERENCES ies (id)
ON DELETE CASCADE;

-- [artifacts] add ON DELETE action when deleting a row from records
-- get name of foreign key constraint for field 'artifacts.record_id'
SELECT con.conname AS constraint_name
FROM pg_constraint AS con
JOIN pg_class tbl ON tbl.oid = con.conrelid
JOIN LATERAL unnest(con.conkey) AS colnum(attnum) ON TRUE
JOIN pg_attribute attr ON attr.attrelid = tbl.oid AND attr.attnum = colnum.attnum
WHERE con.contype = 'f'
  AND tbl.relname = 'artifacts'
  AND attr.attname = 'record_id';
-- drop existing constraint (assuming the name of foreign key constraint is 'artifacts_record_id_fkey')
ALTER TABLE artifacts
DROP CONSTRAINT artifacts_record_id_fkey;
-- add a new constraint with ON DELETE action
ALTER TABLE artifacts
ADD CONSTRAINT artifacts_record_id_fkey
FOREIGN KEY (record_id)
REFERENCES records (id)
ON DELETE SET NULL;

-- [job_collections] add table 'job_collections'
CREATE TABLE job_collections (
  id uuid NOT NULL PRIMARY KEY,
  job_config_id uuid REFERENCES job_configs (id) ON DELETE SET NULL,
  completed boolean
);
-- [jobs] add column 'collection_id' to 'jobs'-table
ALTER TABLE jobs ADD collection_id uuid REFERENCES job_collections (id) ON DELETE SET NULL;
-- [records] add column 'collection_id' to 'records'-table
ALTER TABLE records ADD collection_id uuid REFERENCES job_collections (id) ON DELETE SET NULL;

INSERT INTO migrations (from_version, to_version, completed_at) VALUES ('3.0.0', '3.4.0', current_timestamp);
UPDATE deployment SET schema_version = '3.4.0' WHERE schema_version = '3.0.0';
COMMIT;
