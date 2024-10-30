# dcm-database
This repository contains scripts and documentation for the DCM Database container.

## General
The database is structured into three tables that can be used like a key-value-store (mappings of an identifier to a JSON object):
* configurations: job and user configurations
* job-reports: maps a token to the associated Report
* preservation-info: *\<omitted for now>*

## PostgreSQL

### General
PostgreSQL is basically used as a NoSQL-database by relying on the `JSONB`-type for storing the above-mentioned JSON-data.

### Tables/Schemas
The following definitions are used for the individual tables (see initialization script for details)
* `configurations`: `(config_id UUID, config JSONB)`
* `reports`: `(token UUID, report JSONB)`
* `preservation`: *\<omitted for now>*

### Docker
Run a docker container with the following properties
* deleted when stopped
* name `dcm-database`
* locally mounted database-directory at `./postgres-data`
* (or if empty `./postgres-data` is empty) pre-configured (empty) tables (using the script `./postgres/init.sql`)
* user `postgres` and password `foo`
* database name `postgres`
* mapped port `5432`
via
```
docker run --rm --name dcm-database -v ./postgres-data:/var/lib/postgresql/data -v ./postgres/init.sql:/docker-entrypoint-initdb.d/init-database.sql -e POSTGRES_PASSWORD=foo -p 5432:5432 postgres:14.13
```
Test the running container by, for example, running (adding empty configuration, running a query for all configurations, and truncating the `configurations`-table)
```
docker exec -it -u postgres dcm-database psql -c "INSERT INTO configurations VALUES (DEFAULT, '{}');"
docker exec -it -u postgres dcm-database psql -c "SELECT * FROM configurations;"
docker exec -it -u postgres dcm-database psql -c "TRUNCATE configurations;"
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

# Contributors
* Sven Haubold
* Orestis Kazasidis
* Stephan Lenartz
* Kayhan Ogan
* Michael Rahier
* Steffen Richters-Finger
* Malte Windrath
