---
description: Interview me to clarify a task before planning
argument-hint: "<task>"
---

Use `ops` and `architect`.

Clarify the task before planning: $ARGUMENTS

1. Ask one focused question at a time, with a recommended answer or default.
2. Inspect discoverable repository facts instead of asking the user. Use direct tools for a simple lookup or a bounded scout only when ops' delegation criteria justify it.
3. Stop questioning once behavior, constraints, non-goals, data implications, and acceptance are clear enough. Do not invent ambiguity or implement while interviewing.
4. Return the canonical ops brief with key decisions, assumptions, and remaining questions. This clarification step does not itself launch a planner or authorize implementation; `/plan` owns the delegated planning flow.
