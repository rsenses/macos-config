---
description: Execute the approved/current plan
argument-hint: "<prompt>"
---

Use the `dev` and `ops` (worker) skills.

**Goal**: Implement the current plan for: "$ARGUMENTS"
**Rules**:
1. Read the plan before starting.
2. Execute in vertical slices following `dev` rules.
3. Use `worker` subagents with explicit validation policies.
4. Stop if the plan conflicts with the codebase.
