---
description: Apply a focused correction to the current implementation
argument-hint: "<feedback>"
---

Use the `orchestrator` skill for this task.

Apply a focused correction to the current implementation based on my feedback.

User feedback:
$ARGUMENTS

Rules:

- Treat the feedback above as the main instruction.
- If no feedback was provided, ask me what correction I want.
- Inspect the current git diff before changing anything.
- Do not restart or re-plan the task unless strictly necessary.
- Do not broaden scope.
- Do not modify unrelated files.
- Do not introduce unrelated refactors.
- Do not run the full test suite, formatters, refactor commands, or reviewer agents unless explicitly requested.
- Use `worker` only for small, concrete file edits.
- Do not use `reviewer` by default.
- If the requested correction contradicts the saved/current plan, stop and explain the contradiction before changing files.
- If the requested correction is larger than a focused fix, explain why and suggest returning to planning.
- Prefer short decisions and fast delegation.
- Avoid long reasoning chains.
- Execute directly when the requested fix is clear.
- Do not let memory broaden the requested fix.

Validation:

- Run PHPStan after applying the requested fix when relevant.
- PHPStan is allowed during this phase because it catches many issues cheaply.
- Prefer the narrowest relevant PHPStan command if the project supports one.
- Do not claim full validation unless the full validation flow was explicitly requested.

Final output:

- feedback applied
- files changed
- concise diff summary
- PHPStan status, if run
- anything I should manually review again
