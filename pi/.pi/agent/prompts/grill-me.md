---
description: Interview me to clarify a task before planning
argument-hint: "<task>"
---

Use the `orchestrator` skill for this task.
Use `spec-driven-development` lightly: clarify the behavior contract, not a heavy document.

Interview me to clarify the task before planning.

Task:
$ARGUMENTS

Goal:
Reach a shared understanding of what should be done, why it matters, and what constraints affect the implementation.

Rules:

- Do not implement code.
- Do not create, edit, delete, move, or rename files.
- Ask one focused question at a time.
- For each question, include your recommended answer or default choice.
- Prefer high-value questions over a long questionnaire.
- Walk through dependent decisions in order: resolve earlier decisions before asking follow-up questions that depend on them.
- If a question can be answered by inspecting the codebase, inspect the codebase instead of asking me.
- Use `scout` when codebase discovery would clarify the task.
- Use `researcher` when framework, library, package, or API behavior matters.
- Follow project-specific instructions from AGENTS.md and related project guidance.
- Prefer MCP/documentation tools when available.
- Keep the conversation practical and implementation-oriented.
- Stop asking when the task is clear enough to produce a useful plan.

Focus on:

- desired outcome
- user-visible behavior
- edge cases
- non-goals
- affected areas
- data/model implications
- validation needs
- risks or constraints
- naming and terminology

When enough information is gathered, summarize:

- clarified goal
- Spec / Contract summary
- important decisions
- unresolved assumptions, if any
- recommended next step
