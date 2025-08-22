# Changelog

## [1.4.0] - 2025-08-22

### Changed

- changed `user_groups.workspace_id` to trigger cascade on delete
- changed `templates.workspace_id` to trigger set null on delete
- changed `job_configs.template_id` to trigger cascade on delete

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
