BEGIN TRANSACTION;

-- PLACE MIGRATION STATEMENTS HERE

-- [templates] add column 'target_archive'
ALTER TABLE templates ADD target_archive jsonb;

INSERT INTO migrations (from_version, to_version, completed_at) VALUES ('2.0.0', '2.1.0', current_timestamp);
UPDATE deployment SET schema_version = '2.1.0' WHERE schema_version = '2.0.0';
COMMIT;
