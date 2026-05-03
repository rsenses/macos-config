---
description: Interview me to clarify a task before planning
argument-hint: "<task>"
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the codebase instead.

Task:
$ARGUMENTS

Goal:
Reach a shared understanding of what should be done, why, and what constraints matter.

Rules:

- Do not implement code.
- Do not create files.
- If framework/library behavior matters, consult official documentation first.
- Prefer MCP documentation tools when available.
- Keep the conversation practical and implementation-oriented.
- Stop asking when the task is clear enough to produce a plan.

Focus on:

- desired outcome
- user-visible behavior
- edge cases
- non-goals
- affected areas
- data/model implications
- validation needs
- risks or constraints

When enough information is gathered, summarize:

- clarified goal
- important decisions
- unresolved assumptions, if any
- recommended next step
