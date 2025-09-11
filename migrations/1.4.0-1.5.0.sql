BEGIN TRANSACTION;

-- drop unused table
DROP TABLE hotfolder_import_sources;

INSERT INTO migrations (from_version, to_version, completed_at) VALUES ('1.4.0', '1.5.0', current_timestamp);
UPDATE deployment SET schema_version = '1.5.0' WHERE schema_version = '1.4.0';
COMMIT;
