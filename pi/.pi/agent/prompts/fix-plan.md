---
description: Apply a focused correction to the current implementation
argument-hint: "<feedback>"
---

Use the `worker` subagent for this task.

Apply a focused correction to the current implementation based on my feedback.

User feedback:
$ARGUMENTS

Rules:

- Treat the feedback above as the main instruction.
- If no feedback was provided, ask me what correction I want.
- Inspect the current git diff before changing anything.
- Do not restart the plan.
- Do not run the full test suite, formatters, refactor commands, or reviewer agents unless explicitly requested.
- PHPStan is allowed and should be run after code changes when relevant.
- Do not modify unrelated files.
- Do not broaden scope.

Validation:

- Run PHPStan after applying the requested fix when relevant.
- PHPStan is allowed during this phase because it catches many issues cheaply.
- Do not run the full test suite, formatters, refactors, or reviewer agents unless explicitly requested.

Final output:

- feedback applied
- files changed
- concise diff summary
- PHPStan status, if run
- anything I should manually review again
