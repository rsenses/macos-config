---
description: Execute the approved/current plan
---

Use the `orchestrator` skill for this task.
Use the `memory` skill for this task.

Implement the approved/current plan, but do not run the full validation flow yet.

Context:
The implementation should follow the current agreed plan or the latest saved plan in `.ai/plan/` when available.

Rules:

- Read the approved/current plan before changing files.
- Focus only on implementation.
- Do not restart or redesign the plan.
- If no clear plan exists, stop and ask me to run `/plan` or clarify the task.
- Use `scout` only if needed to locate files, entry points, existing patterns, or affected areas.
- Use `worker` for small focused implementation edits. The main agent may make tiny
  direct edits when delegation would be unnecessary overhead.
- Give each worker a bounded task with:
  - exact objective
  - relevant plan context
  - likely files or areas
  - constraints
  - what not to change
  - acceptance criteria
- Do not ask a worker to implement the whole plan at once unless the plan is genuinely tiny.
- Do not invoke `reviewer` unless there is uncertainty or a possible contradiction with the plan.
- Do not run tests.
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

- Run PHPStan after implementation changes when relevant.
- PHPStan is allowed during this phase because it catches many issues cheaply.
- Prefer the narrowest relevant PHPStan command if the project supports one.
- Do not run the full test suite, formatters, refactors, or reviewer agents unless explicitly requested.
- Do not claim full validation unless the full validation flow was explicitly requested.

Final output:

- files changed
- concise summary
- memory/daily entry status
- important assumptions
- PHPStan status, if run
- anything I should manually r-eview first
