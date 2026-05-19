---
description: Run fix and test, then leave the task ready for final review
---

Use the `ops`, `architect`, and `dev` skills. Use worker for file edits only.

1. **Validation**: Identify and run project-specific fix/format and test commands. Summarize file changes and failures.
2. **Changelog**: Check if `CHANGELOG.md` needs a SemVer entry for user-visible changes. Add it if required.
3. **Escalation**: Only use `reviewer` if formatting changes logic or readiness is ambiguous.
4. **Persistence**: Use memory tools (`add_daily_note`, `create_session_plan`) to update `.ai/` files before finishing.
5. **Outcome**: Propose a `type(scope): summary` commit message based on the task goal. Do not commit automatically.

Final Output:
- Executed checks and test status.
- Files modified by fixers.
- Changelog and working tree status.
- Blocking/non-blocking issues and risks.
- Final verdict: `ready to ship` or `not ready to ship`.
- Conventional Commit suggestion.
- Memory/daily entry status.
