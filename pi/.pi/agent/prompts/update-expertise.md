---
description: Update project memory with durable lessons
argument-hint: "[lesson or focus]"
---

Use the `ops` skill.

Update the project's durable memory based on the current conversation ($ARGUMENTS).

**Rules**:
1. Store durable knowledge in `.ai/MEMORY.md`.
2. Use `add_daily_note` for task-specific outcomes and temporary context.
3. Read existing `.ai/MEMORY.md` before updating to avoid duplicates.
4. Capture: architecture decisions, stable preferences, recurring pitfalls, and workflow rules.
5. Skip: one-off details, command outputs, or guesses.

**Output**:
- Files updated and summary of durable lessons added.
