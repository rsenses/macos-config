---
description: Execute the approved plan
---

Use the `worker` subagent for this task.

Implement the approved/current plan, but do not run tests, formatters, refactors, or reviewer agents yet.

Rules:

- Focus only on implementation.
- Use the `scout` subagent only if needed to locate files.
- Use workers for small focused edits.
- Do not invoke the `reviewer` subagent unless there is uncertainty or a possible contradiction with the plan.
- Do not run tests.
- Do not run formatters.
- Do not run refactor commands.
- Do not broaden scope.
- Stop if the plan is unclear or risky.

Validation:

- Run PHPStan after implementation changes when relevant.
- PHPStan is allowed during this phase because it catches many issues cheaply.
- Do not run the full test suite, formatters, refactors, or reviewer agents unless explicitly requested.

Final output:

- files changed
- concise summary
- important assumptions
- PHPStan status, if run
- anything I should manually review first
