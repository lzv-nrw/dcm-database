from setuptools import setup


setup(
    version="3.0.0",
    name="dcm-database",
    description="database for the dcm",
    author="LZV.nrw",
    license="MIT",
    install_requires=[
    ],
    packages=[
        "dcm_database",
    ],
    package_data={
        "dcm_database": [
            "dcm_database/init.sql",
        ],
    },
    include_package_data=True,
    setuptools_git_versioning={
          "enabled": True,
          "version_file": "VERSION",
          "count_commits_from_version_file": True,
          "dev_template": "{tag}.dev{ccount}",
    },
)
