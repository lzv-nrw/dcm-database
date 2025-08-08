BEGIN TRANSACTION;

-- [user_secrets] add ON DELETE action when deleting a user
-- get name of foreign key constraint for field 'user_secrets.user_id'
SELECT con.conname AS constraint_name
FROM pg_constraint AS con
JOIN pg_class tbl ON tbl.oid = con.conrelid
JOIN LATERAL unnest(con.conkey) AS colnum(attnum) ON TRUE
JOIN pg_attribute attr ON attr.attrelid = tbl.oid AND attr.attnum = colnum.attnum
WHERE con.contype = 'f'
  AND tbl.relname = 'user_secrets'
  AND attr.attname = 'user_id';
-- drop existing constraint (assuming the name of foreign key constraint is 'user_secrets_user_id_fkey')
ALTER TABLE user_secrets
DROP CONSTRAINT user_secrets_user_id_fkey;
-- add NOT NULL constraint again (this constraint should be maintained, but re-apply to be sure)
ALTER TABLE user_secrets
ALTER COLUMN user_id SET NOT NULL;
-- add a new constraint with ON DELETE action
ALTER TABLE user_secrets
ADD CONSTRAINT user_secrets_user_id_fkey
FOREIGN KEY (user_id)
REFERENCES user_configs (id)
ON DELETE CASCADE;

-- [user_groups] add ON DELETE action when deleting a user
-- get name of foreign key constraint for field 'user_groups.user_id'
SELECT con.conname AS constraint_name
FROM pg_constraint AS con
JOIN pg_class tbl ON tbl.oid = con.conrelid
JOIN LATERAL unnest(con.conkey) AS colnum(attnum) ON TRUE
JOIN pg_attribute attr ON attr.attrelid = tbl.oid AND attr.attnum = colnum.attnum
WHERE con.contype = 'f'
  AND tbl.relname = 'user_groups'
  AND attr.attname = 'user_id';
-- drop existing constraint (assuming the name of foreign key constraint is 'user_groups_user_id_fkey')
ALTER TABLE user_groups
DROP CONSTRAINT user_groups_user_id_fkey;
-- add NOT NULL constraint again (this constraint should be maintained, but re-apply to be sure)
ALTER TABLE user_groups
ALTER COLUMN user_id SET NOT NULL;
-- add a new constraint with ON DELETE action
ALTER TABLE user_groups
ADD CONSTRAINT user_groups_user_id_fkey
FOREIGN KEY (user_id)
REFERENCES user_configs (id)
ON DELETE CASCADE;

-- drop NOT NULL constraint from username and email in user_configs-table
ALTER TABLE user_configs ALTER COLUMN username DROP NOT NULL;
ALTER TABLE user_configs ALTER COLUMN email DROP NOT NULL;

-- add constraints to deployment table to
-- * only ever contain a single col per row and
-- * have a unique (non-null) schema_version column
ALTER TABLE deployment
ADD CONSTRAINT only_one_active
CHECK (
    (CASE WHEN schema_loaded IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN schema_version IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN demo_loaded IS NOT NULL THEN 1 ELSE 0 END)
    = 1
);
CREATE UNIQUE INDEX only_one_schema_version ON deployment ((1)) WHERE schema_version IS NOT NULL;

-- create new migrations-table
CREATE TABLE migrations (
  from_version text UNIQUE,
  to_version text UNIQUE,
  completed_at text
);

INSERT INTO migrations (from_version, to_version, completed_at) VALUES ('1.0.0', '1.3.0', current_timestamp);
UPDATE deployment SET schema_version = '1.3.0' WHERE schema_version = '1.0.0';
COMMIT;
