---
description: Plan a task and optionally update domain docs
argument-hint: "<task>"
---

Use the `architect` skill and the `planner` subagent.

**Goal**: Create a technical plan for the task: "$ARGUMENTS"

**Rules**:

1. Planning-first: do not modify implementation files. Writing/updating the session plan file is OK.
2. The architect must first translate the request into a canonical brief. If the request has domain language or unclear decisions, use `grill-with-docs` before planning.
3. For non-trivial tasks, call `create_session_plan` with a short slug first to get the plan file path.
4. Pass the canonical brief, not the raw user wording, to `subagent(agent: "planner", task: "...")`.
5. Review the planner's output. If the plan has gaps or wrong assumptions, ask the planner to refine a specific section or fix minor issues yourself.
6. Write the final plan into the session plan file from step 3.
7. Present a summary to the user: goal, key tasks, files involved, risks, and dependencies.

**Note**: The planner has `scout` and `researcher` subagents. It explores the codebase and external docs as needed, so you do not need to pre-investigate.
