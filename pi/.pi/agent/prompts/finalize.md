---
description: Run fix and test, then leave the task ready for final review
---

Use `ops` and `dev`. Load `architect` only for a real design question. Delegate a substantive correction when the ops criteria justify it, not merely to perform a trivial file edit.

1. Read the project's validation instructions and relevant scripts. Use the authoritative full-project commands rather than inventing narrower substitutes.
2. Check the working diff and apply APPEND_SYSTEM's Changelog Policy before final validation. Update required entries; do not create a new changelog unless explicitly required. Absence alone is not a blocker when no policy requires that file.
3. Execute ops section 4's full completion gate: complete fix/format/lint followed by complete tests, with successful natural completion on the post-fix tree. A worker's success, targeted checks, or dry runs cannot replace it. Unsafe or unavailable commands remain blockers, not permission to fake success.
4. Inspect fixer-produced changes and summarize the actual commands, exit statuses, skips, and failures. If any required check is incomplete, report `not ready to ship`, including failures unrelated to this task without broadening scope to fix them automatically.
5. Use scout/researcher only for an unresolved evidence question worth delegating. Never invoke the manual-only plan-reviewer automatically.
6. Update the existing plan's validation and status when there is one. Do not create another plan just to record completion; handle an absent/blocked selection according to ops instead of guessing a file.
7. Report the useful delta once and propose a Conventional Commit message. Do not commit or make remote changes.

Final output:

- Changes and files modified by fixers.
- Executed checks, exit statuses, skips, and failures.
- Applicable changelog and working-tree status.
- Blocking/non-blocking issues and risks.
- `ready to ship` only when the full gate passed; otherwise `not ready to ship` and why.
- Conventional Commit suggestion and plan persistence status.
