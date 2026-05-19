---
description: Interview me to clarify a task before planning
argument-hint: "<task>"
---

Use the `ops` and `architect` skills.

Interview me to clarify the task before planning ($ARGUMENTS).

**Rules**:
1. Ask one focused question at a time.
2. Include your recommended answer or default choice for each question.
3. Use `scout` (ops) to inspect the codebase instead of asking if the answer is discoverable.
4. Stop asking when the task is clear enough to produce a plan in `architect`.

**Focus on**:
- User-visible behavior and edge cases.
- Constraints, non-goals, and affected areas.
- Data model implications and validation needs.

**Output (when done)**:
- Clarified goal.
- Spec / Contract summary.
- Key decisions and assumptions.
