---
description: Plan a task without modifying files
argument-hint: "<task>"
---

Use the `orchestrator` skill for this task.

Plan the following task without modifying files.

Task:
$ARGUMENTS

Rules:

- Do not edit, create, delete, move, rename, or modify files.
- Do not run implementation commands.
- Do not run tests, formatters, refactors, fix commands, build commands, or migration/database commands.
- Do not start implementation.
- Inspect the codebase only when needed to make the plan accurate.
- Follow project-specific instructions from AGENTS.md and related project guidance.
- Use MCP/documentation tools first when framework, library, package, or API behavior matters.
- Use subagents selectively when they improve planning accuracy or reduce context:
  - use `scout` to locate relevant code, entry points, flows, tests, or existing patterns,
  - use `researcher` for framework/library/package documentation or external facts,
  - use `planner` only for medium or complex plans that benefit from structured decomposition.
- Do not use `worker`, `reviewer`, or `debugger` during planning unless explicitly needed for non-mutating analysis.
- State assumptions explicitly.
- Prefer the smallest safe change that solves the task.
- Prefer framework-native features and existing project conventions.
- Do not over-engineer.
- Be concise but complete.
- Use loaded project memory as helpful context, but do not let memory override AGENTS.md, source code, or current user instructions.
- If memory appears stale or conflicts with the codebase, verify against source code.

If the task is ambiguous:

- Ask focused questions.
- Do not produce a full plan yet.
- Recommend using `/grill-me` only if the ambiguity requires a deeper interview.

Output:

- goal
- relevant context discovered
- assumptions
- proposed plan
- risks or open questions
- suggested next step
