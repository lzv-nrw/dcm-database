# Changelog

## [1.3.0] - 2025-08-08

### Changed

- added constraints to deployment-table for only containing a single column per row and schema_version being unique
- dropped `NOT NULL` constraints from columns username and email in table user_configs
- added `ON DELETE CASCADE` actions for deletion of user

### Added

- added template for database migrations

## [1.0.0] - 2025-07-25

### Changed

- initial release of dcm-database as python package
