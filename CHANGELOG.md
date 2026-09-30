# Changelog

All notable changes to this project are documented here using Keep a Changelog and Semantic Versioning.

## [Unreleased]

### Changed
- Planner profiles now use `openai-codex/gpt-6.1-sol` at `low` by default, with justified `medium` and `high` escalation. Profile names are now `low`, `medium`, and `high`, replacing `habitual`, `diseno`, and `delicado`.

### Fixed
- Planner launches without an explicit profile fail when low is unavailable instead of proposing a higher thinking level.
