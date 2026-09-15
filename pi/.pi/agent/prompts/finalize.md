---
description: Run fix and test, then leave the task ready for final review
---

Use the `ops`, `architect`, and `dev` skills. Use worker for file edits only.

1. **Validation command discovery**: Read the project instructions first, especially `AGENTS.md` / `agents.md` if present, plus package scripts (`composer.json`, `package.json`, `justfile`, `Makefile`, etc.) only as needed. Prefer the validation commands explicitly documented by the project over inventing narrower checks.
2. **Non-negotiable full-suite gate**: Run the complete project fix/format/lint command(s) and the complete project test command(s) before declaring anything ready. Do not substitute targeted tests, single-file checks, feature-specific commands, dry runs, filtered selectors, or a worker's success. For Laravel/PHP projects, if the project documents `composer fix` and `composer test`, run exactly `composer fix` and then exactly `composer test`, from the project root.
3. **Successful execution only**: Count a command only if it was actually executed to natural completion and exited 0. If the fixer changes files, inspect and report those changes; the complete test suite must run against the post-fix tree.
4. **If full validation is impractical**: If any required full-suite command is missing, unsafe, too expensive, unavailable, interrupted, timed out, or fails—even for reasons unrelated to the task—say so explicitly and report `not ready to ship`. User acceptance of the limitation does not change that verdict.
5. **Results**: Summarize every fix/format/lint/test command executed, exit status, file changes made by fixers, skipped commands and reasons, and failures.
6. **Changelog**: If `CHANGELOG.md` exists at the project root, verify it has an up-to-date SemVer-aligned Keep a Changelog entry for this job's user-visible changes. Add or update it before reporting `ready to ship`; if it is missing or stale, report `not ready to ship`.
7. **Escalation**: Only use `scout`/`researcher` if readiness is ambiguous or you need extra context. Do not invoke the manual-only `plan-reviewer` unless the user explicitly requests a saved-plan review.
8. **Persistence**: Use planning tools (`get_current_plan`) to reference the active plan and update `.ai/` files before finishing. Do not create a new session plan during finalize unless no plan exists and the task was non-trivial.
9. **Reporting**: Prefer deltas and unresolved items over reprinting the whole plan or any inventory already captured in it.
10. **Outcome**: Propose a `type(scope): summary` commit message based on the task goal. Do not commit automatically.

Final Output:

- Executed checks and test status.
- Files modified by fixers.
- Changelog and working tree status.
- Blocking/non-blocking issues and risks.
- Final verdict: `ready to ship` only when every required full validation command passed; otherwise `not ready to ship`.
- Conventional Commit suggestion.
- Task/plan persistence status.
