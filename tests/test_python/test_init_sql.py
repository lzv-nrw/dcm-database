"""
Test compatibility of database-schema with database-implementation via
dcm-common adapters.

In order to run the tests for the class `PostgreSQLAdapterSQL14`,
a PostgreSQL-database with the following properties is required:
* host: localhost
* port: 5432
* user: postgres
* password: foo
* database: postgres
The test includes deleting, recreating, and modifying the database
"test"
"""

from pathlib import Path

import pytest
from dcm_common.db import SQLiteAdapter3, PostgreSQLAdapterSQL14

import dcm_database


@pytest.fixture(name="sql_path")
def _sql_path():
    return Path(dcm_database.__file__).parent / "init.sql"


def test_sqlite3(sql_path):
    """
    Test whether the schema is compatible with SQLite3.
    """
    db = SQLiteAdapter3(allow_overflow=False)
    result = db.read_file(sql_path)
    assert result.success, result.msg
    assert len(db.get_table_names(True).eval()) > 0


def test_postgres14(sql_path):
    """
    Test whether the schema is compatible with PostgreSQL14.
    """
    def get_postgres_adapter(**kwargs):
        """Returns PostgreSQL-adapter."""
        return PostgreSQLAdapterSQL14(
            **(
                {
                    "host": "localhost",
                    "port": "5432",
                    "database": "postgres",
                    "user": "postgres",
                    "password": "foo",
                    "pool_size": 1,
                    "allow_overflow": False,
                }
                | kwargs
            )
        )

    try:
        db = get_postgres_adapter()
    # pylint: disable=broad-exception-caught
    except Exception as exc_info:
        pytest.skip(reason=str(exc_info))

    db.custom_cmd("DROP DATABASE test")  # delete testing-database
    db.custom_cmd("CREATE DATABASE test").eval()  # re-create testing-database
    db.pool.close()
    db = get_postgres_adapter(database="test")

    result = db.read_file(sql_path)
    assert result.success, result.msg
    assert len(db.get_table_names(True).eval()) > 0
