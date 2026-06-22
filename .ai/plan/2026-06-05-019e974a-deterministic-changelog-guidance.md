# Plan: deterministic-changelog-guidance
- Status: done
- Created: 2026-06-05
- Session ID: 019e974a

## Goal
Make Pi's changelog requirement deterministic: if a project-root `CHANGELOG.md` exists, jobs with user-visible changes must update it before finalizing.

## Changes Made
- Added a global Changelog Policy to `pi/.pi/agent/APPEND_SYSTEM.md`.
- Strengthened `pi/.pi/agent/prompts/finalize.md` so stale/missing changelog entries block `ready to ship`.
- Added architect planning guidance in `pi/.agents/skills/architect/SKILL.md` to include changelog finalization tasks.
- Added deterministic runtime injection in `pi/.pi/agent/extensions/memory.ts` when `CHANGELOG.md` exists in the current project root.

## Validation
- Inspected `git diff` for the changed files.
- No automated test command was found/run for the Pi dotfiles extension in this repo.

## Stop Rules
- Do not create `CHANGELOG.md` automatically when it does not exist.
- Changelog entries must describe actual current-job user-visible impact; placeholders do not satisfy the policy.
