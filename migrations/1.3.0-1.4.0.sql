BEGIN TRANSACTION;

-- [job_configs] update constraint for template_id
-- drop all existing constraints
DO $$
DECLARE r RECORD;
BEGIN
FOR r IN
SELECT c.conname
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN unnest(c.conkey) AS ck(attnum) ON true
JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ck.attnum
WHERE t.relname = 'job_configs' AND a.attname = 'template_id'
LOOP
EXECUTE format('ALTER TABLE job_configs DROP CONSTRAINT %I', r.conname);
END LOOP;
END$$;
-- add constraint: NOT NULL
ALTER TABLE job_configs
ALTER COLUMN template_id SET NOT NULL;
-- add constraint: ON DELETE CASCADE
ALTER TABLE job_configs
ADD CONSTRAINT job_configs_template_id_fkey
FOREIGN KEY (template_id)
REFERENCES templates (id)
ON DELETE CASCADE;

-- [templates] update constraint for workspace_id
-- drop all existing constraints
DO $$
DECLARE r RECORD;
BEGIN
FOR r IN
SELECT c.conname
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN unnest(c.conkey) AS ck(attnum) ON true
JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ck.attnum
WHERE t.relname = 'templates' AND a.attname = 'workspace_id'
LOOP
EXECUTE format('ALTER TABLE templates DROP CONSTRAINT %I', r.conname);
END LOOP;
END$$;
-- add constraint: ON DELETE SET NULL
ALTER TABLE templates
ADD CONSTRAINT templates_workspace_id_fkey
FOREIGN KEY (workspace_id)
REFERENCES workspaces (id)
ON DELETE SET NULL;

-- [user_groups] update constraint for workspace_id
-- drop all existing constraints
DO $$
DECLARE r RECORD;
BEGIN
FOR r IN
SELECT c.conname
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN unnest(c.conkey) AS ck(attnum) ON true
JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ck.attnum
WHERE t.relname = 'user_groups' AND a.attname = 'workspace_id'
LOOP
EXECUTE format('ALTER TABLE user_groups DROP CONSTRAINT %I', r.conname);
END LOOP;
END$$;
-- add constraint: ON DELETE SET NULL
ALTER TABLE user_groups
ADD CONSTRAINT user_groups_workspace_id_fkey
FOREIGN KEY (workspace_id)
REFERENCES workspaces (id)
ON DELETE CASCADE;

INSERT INTO migrations (from_version, to_version, completed_at) VALUES ('1.3.0', '1.4.0', current_timestamp);
UPDATE deployment SET schema_version = '1.4.0' WHERE schema_version = '1.3.0';
COMMIT;
