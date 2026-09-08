---
description: Create a risk-aware implementation plan
argument-hint: "<task>"
---

Create a plan for: "$ARGUMENTS"

Use a compact canonical contract:

- **Goal**: desired bounded outcome and non-goals.
- **Known**: decisions, invariants, and existing changes to preserve.
- **Evidence**: exact files/ranges, URLs, or excerpts already checked.
- **Acceptance**: observable success conditions.
- **Checks**: concrete local validation.
- **Stop**: ambiguity, scope conflict, missing evidence, or repeated failure.

Rules:

1. Planning only: do not modify implementation files. Updating the session plan file is allowed.
2. For a clear, bounded, low-risk task, plan directly without delegating. Use `architect` and the `planner` subagent only when ambiguity, architecture, material risk, or a genuinely independent planning/investigation slice justifies the handoff; file count alone is not a trigger.
3. If a persisted plan is useful for a non-trivial task, call `create_session_plan` once and use its path. Do not create duplicate plan representations.
4. Give the planner the canonical contract and relevant evidence, not the raw conversation. The principal remains coordinator; planner has no nested subagent tools.
5. Write one ordered checklist to the session plan, including exact files/symbols, dependencies, acceptance, and checks. Keep documentation and summaries selective.
6. Finish with `Status: complete`, `partial`, or `blocked`; report unresolved questions and risks rather than guessing. Present only a brief delta to the user: goal, checklist, files, risks, and dependencies.
