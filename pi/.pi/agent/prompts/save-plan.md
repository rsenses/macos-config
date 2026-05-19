---
description: Save the current agreed plan to a Markdown file
---

Use the `ops` skill and the `create_session_plan` tool.

**Goal**: Persist the latest agreed plan.
**Rules**:
1. Use `create_session_plan(slug)` to get the correct path.
2. Write the plan following the `architect` template.
3. Update `TASKS.md` with a wiki-link `[[path]]` if this is for future work.
