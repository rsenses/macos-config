---
description: Execute the approved/current plan
argument-hint: "<prompt>"
---

Use the `orchestrator` skill for this task.
Use the `memory` skill for this task.
Use `incremental-implementation` for multi-file or multi-step changes.
Use `pragmatic-testing` when behavior changes need targeted evidence.

Implement the approved/current plan, but do not run the full validation flow yet.

User input:
$ARGUMENTS

Context:
The implementation should follow the current agreed plan or the latest saved plan in `.ai/plan/` when available.

Rules:

- Read the approved/current plan before changing files.
- Focus only on implementation.
- Treat any `argument-hint` or `$ARGUMENTS` text as the user's extra prompt for this run.
- If the codebase already shows a clear local pattern, follow it instead of spending extra time on documentation or broader investigation.
- Do not restart or redesign the plan.
- If no clear plan exists, stop and ask me to run `/plan` or clarify the task.
- Use `scout` only if needed to locate files, entry points, existing patterns, or affected areas.
- Use `worker` for small focused implementation edits. The main agent may make tiny
  direct edits when delegation would be unnecessary overhead.
- Decide the validation policy before delegating: `no-tests`, `targeted-check`, `add-test`, `test-first`, or `defer-validation`.
- For normal implementation during `/run-plan`, prefer `defer-validation` or one cheap `targeted-check`; do not ask workers to add tests unless the approved plan explicitly calls for tests.
- Give each worker a bounded task with:
  - exact objective
  - relevant plan context
  - likely files or areas
  - constraints
  - what not to change
  - acceptance criteria
  - validation policy
  - exact targeted project check, only if using `targeted-check`
- Do not ask a worker to implement the whole plan at once unless the plan is genuinely tiny.
- Do not invoke `reviewer` unless there is uncertainty or a possible contradiction with the plan.
- Do not run tests unless the chosen validation policy explicitly requires a targeted test.
- Do not repeat a worker's passing targeted check unless relevant files changed afterward.
- Do not run formatters.
- Do not run refactor commands.
- Do not broaden scope.
- Stop if the plan is unclear, risky, or contradicted by the codebase.
- Prefer not to overthink.
- Execute directly when the plan is clear.
- Avoid long reasoning chains.
- Prefer short decisions and fast delegation.
- Prefer framework-native features and existing project conventions.
- Do not duplicate framework guarantees.
- Do not add new abstractions unless they clearly reduce complexity now.
- Choose the smallest direct implementation that satisfies the plan.
- Use loaded project memory to avoid repeated discovery and known project mistakes, but do not let memory broaden the current task scope.

Validation:

- Run the project's relevant static analysis/type check after implementation changes when it is cheap and useful.
- In PHP/Laravel projects, PHPStan/Larastan is allowed during this phase when relevant because it catches many issues cheaply.
- Prefer the narrowest relevant project check if the project supports one.
- Do not run the full test suite, formatters, refactors, or reviewer agents unless explicitly requested.
- Do not claim full validation unless the full validation flow was explicitly requested.

Final output:

- files changed
- concise summary
- memory/daily entry status
- important assumptions
- targeted check/static analysis status, if run
- anything I should manually r-eview first
