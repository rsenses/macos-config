---
description: Plan a task without modifying files
argument-hint: "<task>"
---

Use the `architect` and `ops` skills.

**Goal**: Create a technical plan for the task: "$ARGUMENTS"
**Rules**:

1. Read-only: Do not modify files.
2. For non-trivial tasks, call `create_session_plan` with a short slug, then write/update the created session plan file. Only skip this for trivial one-line tasks.
3. Investigate: Use `scout` only when relevant code paths, affected files, or existing patterns are unclear. Use `researcher` only when framework/library behavior or external documentation matters. For obvious or small tasks, plan directly without subagents.
4. Structure: Follow the `architect` guidelines (Objective, Assumptions, Tasks with vertical slicing).
5. Output: Present the goal, discovered ctx, assumptions, and proposed tasks.
