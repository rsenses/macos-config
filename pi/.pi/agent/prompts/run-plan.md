---
description: Execute the approved/current plan
argument-hint: "<prompt>"
---

Use the `architect` skill, the `dev` skill, and the `ops` skill.

**Goal**: Implement the current plan for: "$ARGUMENTS"

**Rules**:

1. Read the plan before starting and treat it as the canonical source of truth.
2. Have the architect split the plan into small execution slices and assign them one at a time to workers.
3. If the plan already contains an inventory or report, reuse it by reference and report only new, changed, or missing items.
4. Execute one slice at a time. Use the cheapest credible validation for that slice, usually PHPStan or a targeted check. Do not run the full test/fix flow unless explicitly requested.
5. Use `worker` subagents with explicit validation policies. Workers may use `scout` and `researcher` as needed, but must return ambiguity or repeated failure upward to the architect.
6. If the same failure repeats twice, or the plan conflicts with the codebase, stop, update the plan, or ask.
