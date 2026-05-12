# Project Memory

Durable project knowledge, decisions, preferences, and recurring lessons.

## Stable Preferences

- Prefer simple, direct implementations.
- Prefer framework-native and project-native solutions.
- Avoid unnecessary abstractions.
- Do not duplicate framework guarantees.

## Project Decisions

- Memory POC: pending work lives in `.ai/TASKS.md`; simple tasks are one-line checkboxes and complex tasks link to plans with wiki links like `[[.ai/plan/file.md]]`.
- Memory POC: use one current session plan file (`.ai/plan/YYYY-MM-DD-<session-id>-<short-slug>.md`) and update it across turns instead of creating a new plan per interaction; session id prevents duplicates, slug keeps filenames readable.
- Validation:
- Remaining:
- Notes:
- `project_search` should treat user queries defensively: prefer literal text first so snippets with metacharacters like `$ARGUMENTS` or `->mount(` work naturally, and keep explicit regex as an opt-in only path.
- When finalizing commits, prefer the task's user-facing goal or current session plan Goal / Expected Changes over low-level implementation wording when choosing the commit summary.
