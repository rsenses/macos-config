---
description: Revise the session plan based on feedback or errors
argument-hint: "<reason>"
---

Use the `architect` skill and the `planner` subagent.

**Goal**: Update the current plan due to: "$ARGUMENTS"

**Rules**:

1. This revises the plan document, not the implementation.
2. Locate the existing session plan file.
3. If the update introduces new ambiguity or changed assumptions, have the architect re-translate the request into a canonical brief before calling planner.
4. Delegate the revision of the affected plan sections to the `planner` subagent when it needs fresh investigation or clearer structure.
5. Revise only the sections affected by new evidence. Keep unchanged inventories and decisions as references instead of duplicating them.
6. Ensure the updated plan stays consistent with `architect` guidelines and remains concrete, ordered, and actionable.
