---
description: Execute the approved/current plan
argument-hint: "<prompt>"
---

Use the `dev` and `ops` (worker) skills.

**Goal**: Implement the current plan for: "$ARGUMENTS"
**Rules**:
1. Read the plan before starting.
2. Execute one slice at a time, following `dev` rules and validating before moving on.
3. Use `worker` subagents with explicit validation policies.
4. If the same failure repeats twice, or the plan conflicts with the codebase, stop, update the plan, or ask.
