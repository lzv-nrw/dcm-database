BEGIN TRANSACTION;

-- PLACE MIGRATION STATEMENTS HERE

INSERT INTO migrations (from_version, to_version, completed_at) VALUES ('<old-version>', '<new-version>', current_timestamp);
UPDATE deployment SET schema_version = '<new-version>' WHERE schema_version = '<old-version>';
COMMIT;
