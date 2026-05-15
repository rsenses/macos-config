# Pi context warning notification

- Status: in-progress
- Updated: 2026-05-14 14:24
- Scope: small

## Goal

Compare a few external Pi-friendly search options and decide which one best fits a follow-up search tool for Pi.

## Spec / Contract

- Objective: compare candidate tools/packages that could improve code search beyond the built-in literal/regex search.
- Expected behavior: produce a short recommendation with tradeoffs, fit, and complexity for Pi.
- Success criteria: identify one or two best-fit options and note when not to use them.
- Out of scope: implementation changes, code edits, or building a new search engine from scratch.
- Open questions: none.

## Current Plan

1. Compare the candidate options by search style, Pi fit, and maintenance cost.
2. Recommend the best next-step tool split for Pi.
3. Refresh the task list and daily note.

## TODO

- [x] Review candidate options.
- [x] Refresh `.ai/TASKS.md`.
- [x] Add a concise daily note.

## Decisions and Constraints

- Prefer Pi-native extensions/packages over external services when possible.
- Favor tools that improve search effectiveness without making the default tool dishonest.

## Validation

- Web research only.
- `git diff --check` not needed for this research-only step.

## Remaining / Next

- Prepare a concise recommendation for the best fit.

## Related Notes

- Added a minimal global Pi preference in `pi/.pi/agent/APPEND_SYSTEM.md` to prefer `fd` over `find` when both are available.

## Related Investigation

- `project_files` fails when the query contains `/` because the tool passes the query directly to `fd` as a fixed-string search pattern.
- Verified that `project_files({ query: "project-context.ts" })` works, while slash-containing path queries do not.
- Relevant source: `pi/.pi/agent/extensions/project-context.ts`.
- Repo-local Pi extensions live under `pi/.pi/agent/extensions/`.
