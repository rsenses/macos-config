---
description: Apply a focused correction to the current implementation
argument-hint: "<feedback>"
---

Use the `orchestrator` skill for this task.
If the correction touches multiple files or can be split into bounded pieces, actually delegate focused work through orchestrator (e.g. scout/worker/reviewer) instead of doing everything in the main agent.
Use the `memory` skill for this task.
Use `incremental-implementation` if the correction touches multiple files.
Use `pragmatic-testing` when the correction changes behavior.

Apply a focused correction to the current implementation based on my feedback.

User feedback:
$ARGUMENTS

Rules:

- Treat the feedback above as the main instruction.
- If no feedback was provided, ask me what correction I want.
- If the current diff or nearby code already shows a clear pattern, follow it instead of spending extra time on documentation or broader investigation.
- Inspect the current git diff before changing anything.
- Do not restart or re-plan the task unless strictly necessary.
- Do not broaden scope.
- Do not modify unrelated files.
- Do not introduce unrelated refactors.
- Do not run the full test suite, formatters, refactor commands, or reviewer agents unless explicitly requested.
- Decide the validation policy before delegating: usually `targeted-check` for a focused correction, `test-first` only when reproducing a bug matters, or `defer-validation` for simple edits.
- Use `worker` only for small, concrete file edits.
- Tell workers the validation policy explicitly; do not let them add tests or run broad checks unless requested.
- Do not use `reviewer` by default.
- If the requested correction contradicts the saved/current plan, stop and explain the contradiction before changing files.
- If the requested correction is larger than a focused fix, explain why and suggest returning to planning.
- Prefer short decisions and fast delegation.
- Avoid long reasoning chains.
- Execute directly when the requested fix is clear.
- Use loaded project memory only to avoid repeated mistakes or known project pitfalls.
- Do not let memory broaden the requested fix.
- Append a concise daily note only if the correction involved meaningful work.

Validation:

- Run the project's relevant static analysis/type check after applying the requested fix when it is cheap and useful.
- Do not repeat a worker's passing targeted check unless relevant files changed afterward.
- In PHP/Laravel projects, PHPStan/Larastan is allowed during this phase when relevant because it catches many issues cheaply.
- Prefer the narrowest relevant project check if the project supports one.
- Do not claim full validation unless the full validation flow was explicitly requested.

Final output:

- feedback applied
- files changed
- concise diff summary
- targeted check/static analysis status, if run
- anything I should manually review again
