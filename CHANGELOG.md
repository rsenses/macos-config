# Changelog

All notable changes to this project are documented here using Keep a Changelog and Semantic Versioning.

## [Unreleased]

### Changed
- Pi now requires concise, plain-language plan proposals, progress, blockers, resumptions, and completion reports while retaining detailed execution plans and validation gates.
- Planner profiles now use `openai-codex/gpt-6.1-sol` at `low` by default, with justified `medium` and `high` escalation. Profile names are now `low`, `medium`, and `high`, replacing `habitual`, `diseno`, and `delicado`.

### Fixed
- Moved memory regression tests outside Pi's extension discovery directory so they are not loaded as extension factories.
- Plan status displays resolve task IDs to descriptions and preserve next-step and blocker explanations instead of relying on opaque task codes.
- Planner launches without an explicit profile fail when low is unavailable instead of proposing a higher thinking level.
