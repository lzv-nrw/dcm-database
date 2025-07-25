CREATE TABLE deployment (
  id uuid NOT NULL PRIMARY KEY,
  schema_loaded boolean,
  schema_version text,
  demo_loaded boolean
);

CREATE TABLE user_configs (
  id uuid NOT NULL PRIMARY KEY,
  external_id text,
  status text,
  username text UNIQUE NOT NULL,
  firstname text,
  lastname text,
  email text NOT NULL,
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
  workspace_id uuid REFERENCES workspaces (id) NULL,
  name text,
  description text,
  type text,
  additional_information jsonb,
  user_created uuid REFERENCES user_configs (id) ON DELETE SET NULL,
  user_modified uuid REFERENCES user_configs (id) ON DELETE SET NULL,
  datetime_created text,
  datetime_modified text
);

CREATE TABLE user_secrets (
  id uuid NOT NULL PRIMARY KEY,
  user_id uuid REFERENCES user_configs (id) NOT NULL,
  password text NOT NULL
);

-- Auxiliary table to define many-to-many relationships
-- between groups, users and workspaces
CREATE TABLE user_groups (
  id uuid NOT NULL PRIMARY KEY,
  group_id text NOT NULL,
  user_id uuid REFERENCES user_configs (id) NOT NULL,
  workspace_id uuid REFERENCES workspaces (id) NULL,
  UNIQUE (group_id, user_id, workspace_id)
);

-- Add unique constrain to reject duplicates of (user_id, group_id) when workspace_id is NULL
CREATE UNIQUE INDEX user_groups_no_workspace
ON user_groups (user_id, group_id)
WHERE workspace_id is NULL;

-- latest_exec corresponds to token field of jobs-table
-- (omit reference for now to keep sqlite-compatibility, not needed anyway)
CREATE TABLE job_configs (
  id uuid NOT NULL PRIMARY KEY,
  status text,
  template_id uuid REFERENCES templates (id) NOT NULL,
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
  success boolean,
  datetime_started text,
  datetime_ended text,
  report jsonb
);

-- see comment before job_configs-table
-- ALTER TABLE job_configs ADD FOREIGN KEY (latest_exec) REFERENCES jobs(token);

CREATE TABLE records (
  id uuid NOT NULL PRIMARY KEY,
  job_token uuid REFERENCES jobs (token) NOT NULL,
  success boolean NOT NULL,
  report_id text NOT NULL,
  external_id text,
  origin_system_id text,
  sip_id text,
  ie_id text,
  datetime_processed text
);

CREATE TABLE hotfolder_import_sources (
  id uuid NOT NULL PRIMARY KEY,
  name text,
  path text,
  description text
);
