---
description: Run fix and test, then leave the task ready for final review
---

Load `ops` and `dev`; use `architect` only for a real design question.

1. Inspect the working diff and authoritative project validation instructions/scripts. Apply APPEND_SYSTEM's Changelog Policy before validation.
2. Execute ops section 4's full completion gate, then inspect fixer-produced changes. Report actual commands, exit statuses, skips, and failures. No targeted, dry-run, or child-success substitutes; incomplete required checks mean `not ready to ship`. Do not broaden scope to fix unrelated failures.
3. Delegate only a substantive correction or unresolved evidence question that meets ops' criteria. Never invoke plan-reviewer automatically.
4. Update validation/status in the existing plan when selected; do not create a completion plan or guess a target.
5. Report the useful delta, fixer changes, validation evidence, changelog/worktree state, unresolved risks, and plan persistence. Say `ready to ship` only after the full gate passes. Suggest a Conventional Commit message; do not commit or make remote changes.
