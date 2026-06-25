---
description: Run fix and test, then leave the task ready for final review
---

Use the `ops`, `architect`, and `dev` skills. Use worker for file edits only.

1. **Validation command discovery**: Read the project instructions first, especially `AGENTS.md` / `agents.md` if present, plus package scripts (`composer.json`, `package.json`, `justfile`, `Makefile`, etc.) only as needed. Prefer the validation commands explicitly documented by the project over inventing narrower checks.
2. **Full-suite requirement**: Run the complete project fix/format command(s) and the complete project test command(s). Do not substitute targeted tests, single-file checks, or feature-specific commands when full-suite commands are available. For Laravel/PHP projects, if the project documents `composer fix` and `composer test`, run both exactly and in that order.
3. **If full validation is impractical**: If a required full-suite command is missing, unsafe, too expensive, unavailable in the environment, or repeatedly fails for reasons unrelated to the task, say so explicitly and report `not ready to ship` unless the user accepts the limitation.
4. **Results**: Summarize every fix/format/test command executed, exit status, file changes made by fixers, and failures.
5. **Changelog**: If `CHANGELOG.md` exists at the project root, verify it has an up-to-date SemVer-aligned Keep a Changelog entry for this job's user-visible changes. Add or update it before reporting `ready to ship`; if it is missing or stale, report `not ready to ship`.
6. **Escalation**: Only use `scout`/`researcher` if readiness is ambiguous or you need extra context. There is no separate reviewer subagent.
7. **Persistence**: Use memory tools (`get_current_plan`, `add_daily_note`) to reference the active plan and update `.ai/` files before finishing. Do not create a new session plan during finalize unless no plan exists and the task was non-trivial.
8. **Reporting**: Prefer deltas and unresolved items over reprinting the whole plan or any inventory already captured in it.
9. **Outcome**: Propose a `type(scope): summary` commit message based on the task goal. Do not commit automatically.

Final Output:
- Executed checks and test status.
- Files modified by fixers.
- Changelog and working tree status.
- Blocking/non-blocking issues and risks.
- Final verdict: `ready to ship` or `not ready to ship`.
- Conventional Commit suggestion.
- Memory/daily entry status.
