---
description: Plan a task without modifying files
argument-hint: "<task>"
---

Plan the following task without modifying files.

Task:
$ARGUMENTS

Rules:

- Do not edit, create, delete, move, or rename files.
- Do not run implementation commands.
- Do not run tests, formatters, refactors, or fix commands.
- Inspect the codebase only when needed to make the plan accurate.
- Use MCP documentation tools first when framework/library behavior matters.
- For Laravel-specific work, prefer Laravel Boost MCP when available.
- State assumptions explicitly.
- Prefer the smallest safe change that solves the task.
- Do not over-engineer.

If the task is ambiguous:

- Ask focused questions.
- Do not produce a full plan yet.
- Recommend using `/grill-me` if the ambiguity requires a deeper interview.

Output:

- goal
- relevant context discovered
- assumptions
- proposed plan
- risks or open questions
- suggested next step
