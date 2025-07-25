# dcm-database
This repository contains scripts and documentation for the DCM Database container.

The contents of this repository are part of the [`Digital Curation Manager`](https://github.com/lzv-nrw/digital-curation-manager).

## General
The SQL database is defined by the file `./dcm_database/init.sql` and is structured into the following tables:
* `user_configs`: user configurations
* `user_secrets`: separate table to store user secrets
* `workspaces`: workspace configurations
* `templates`: template configurations
* `job_configs`: job configurations
* `jobs`: results of job runs
* `hotfolder_import_sources`: sources for hotfolder imports

In addition, the following auxiliary table is defined to map many-to-many relationships:
* `user_groups`: relationships between `group_id` (*this key is currently not defined anywhere else*), `user_configs.id` and `workspaces.id`.

## PostgreSQL

### Docker
Run a docker container with the following properties
* deleted when stopped
* name `dcm-database`
* locally mounted database-directory at `./postgres-data`
* (or if `./postgres-data` is empty) pre-configured (empty) tables (using the script `./dcm_database/init.sql`)
* user `postgres` and password `foo`
* database name `postgres`
* mapped port `5432`
via
```
docker run --rm --name dcm-database -v ./postgres-data:/var/lib/postgresql/data -v ./dcm_database/init.sql:/docker-entrypoint-initdb.d/init-database.sql -e POSTGRES_PASSWORD=foo -p 5432:5432 postgres:14.13
```
Test the running container by, for example, running (adding empty configuration, running a query for all configurations, and truncating the `configurations`-table)
```
docker exec -it -u postgres dcm-database psql -c "INSERT INTO workspaces (id, name) VALUES ('28b6216e-8702-46fc-a3cf-5d4f001b0a92', 'Workspace 0');"
docker exec -it -u postgres dcm-database psql -c "SELECT * FROM workspaces;"
docker exec -it -u postgres dcm-database psql -c "TRUNCATE workspaces CASCADE;"
```

### psql
Due to the exposed port `5432`, the running database can be interacted with via the front-end client `psql` (i.e., without `docker exec`).
It may be necessary to install additional packages, like in debian, for example,
```
sudo apt install postgresql-client-common postgresql-client
```
Test by running
```
psql -h localhost -p 5432 -U postgres
```

## SQLite

The script `./init.sql` can be used to initialize an SQLite database
via the command-line program `sqlite3`. It may be necessary to install additional packages,
like in debian, for example,
```
sudo apt-get install sqlite3
```
Start the sqlite3 program by running
```
sqlite3
```
Read the script by running
```
.read ./init.sql
```
List the names of tables by running
```
.tables
```
Test by running
```
INSERT INTO workspaces (id, name) VALUES ('28b6216e-8702-46fc-a3cf-5d4f001b0a92', 'Workspace 0');
SELECT * FROM workspaces;
DELETE FROM workspaces;
```

## Tests

### Python
This repository contains `pytest`-tests for general compatibility of the database schema `dcm_database/init.sql` with the database-applications `PostgreSQL` and `SQLite` through the [`dcm-common`](https://github.com/lzv-nrw/dcm-common)-database adapter implementations.

### SQL
To ensure compatibility of all SQL-features used in the schema file `dcm_database/init.sql` for the database-applications `PostgreSQL` and `SQLite`, additional manual tests can be run in the form of SQL-files located in `tests/test_sql`.
These tests first print the expected output followed by the actual output.

#### SQLite
Open a "transient in-memory"-session for SQLite3 with `sqlite3`.
Load the init-file with `.read tests/test_sql/init_sqlite.sql`.
Run tests with the `.read tests/test_sql/X`-command, where `X` is the test-file's name.
The session should be reset in-between tests by closing and re-opening the session.

#### PostgreSQL
Run a database-service as described [above](#docker) and connect with `psql` (it is recommended to use the flags `-q` and `-t`).
The session should be initialized and reset in-between tests by entering `\i tests/test_sql/init_postgres.sql`.
Run tests with the `\i tests/test_sql/X`-command, where `X` is the test-file's name.

# Contributors
* Sven Haubold
* Orestis Kazasidis
* Stephan Lenartz
* Kayhan Ogan
* Michael Rahier
* Steffen Richters-Finger
* Malte Windrath
* Roman Kudinov