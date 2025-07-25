""" Configure the tests """

from pathlib import Path

import pytest


@pytest.fixture(scope="session", name="fixtures")
def _fixtures():
    return Path("tests/test_python/fixtures/")
