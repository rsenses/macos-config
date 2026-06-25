# Plan: finalize-full-suite

## Goal
Make `pi/.pi/agent/prompts/finalize.md` require full project validation commands from project instructions, e.g. Laravel `composer fix` and `composer test`, instead of allowing narrower targeted checks.

## Changes
- Strengthened validation discovery to read `AGENTS.md` / `agents.md` and package scripts as needed.
- Added an explicit full-suite requirement: run complete fix/format and test commands; do not substitute targeted checks when full-suite commands are available.
- Added Laravel/PHP example requiring documented `composer fix` then `composer test`.
- Added `not ready to ship` behavior when full validation is unavailable or impractical.

## Validation
- Reviewed the prompt diff.
- No project `CHANGELOG.md` exists at repo root, so no changelog entry was added.
