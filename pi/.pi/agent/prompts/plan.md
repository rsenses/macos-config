---
description: Create a risk-aware implementation plan
argument-hint: "<task>"
---

Create a plan for: "$ARGUMENTS"

Use one canonical, complete contract:

- **Goal**: desired bounded outcome and non-goals.
- **Known**: decisions, invariants, assumptions, and existing changes to preserve.
- **Evidence**: exact files/ranges, URLs, or excerpts already checked.
- **Acceptance**: observable success conditions.
- **Checks**: concrete local validation.
- **Stop**: ambiguity, scope conflict, missing evidence, or repeated failure.

“Compact” means one canonical plan without duplicated narrative; it does **not** mean a shallow or abbreviated plan. Preserve every material planning detail needed by a reviewer or executor. For each meaningful step, record the action, exact file/symbol or command, relevant behavior/rationale, dependencies or ordering, and validation. Include non-goals, assumptions, risks, and unresolved questions when they affect execution.

Rules:

1. Planning only: do not modify implementation files. Updating the session plan file is allowed.
2. For a clear, bounded, low-risk task, plan directly without delegating. Use `architect` and the `planner` subagent only when ambiguity, architecture, material risk, or a genuinely independent planning/investigation slice justifies the handoff; file count alone is not a trigger.
3. For every non-trivial plan, call `create_session_plan` once and use the exact path it returns. The tool only creates a template: immediately populate that file with the complete plan. If a plan already exists, update that same active plan instead of creating a duplicate.
4. Persistence is mandatory before the final response: the session-plan file is the canonical deliverable and source of truth. Write every substantive detail there, including all task-specific findings and checklist items. Never show a detailed plan in chat while storing a minimal summary, and never treat a brief final response as a substitute for the file. If a planner returns useful detail, incorporate all of it rather than summarizing it away.
5. Give the planner the canonical contract and relevant evidence, not the raw conversation. The principal remains coordinator; planner has no nested subagent tools. Any planner output is provisional until incorporated into the persisted plan.
6. Write one ordered, actionable checklist to the session plan, including exact files/symbols, dependencies, acceptance, checks, risks, and unresolved questions. Keep only duplicated documentation and user-facing summaries selective; do not omit execution detail.
7. After writing, re-read the complete session-plan file from disk and verify that every contract section and every material detail presented or discovered is present. Do not rely on a truncated preview; use the file path and offsets if necessary. If persistence or verification fails, finish with `Status: blocked` rather than claiming the plan is complete.
8. Finish with `Status: complete`, `partial`, or `blocked`; report unresolved questions and risks rather than guessing. Once the full plan is persisted and verified, present only a brief delta to the user: goal, plan path, checklist summary, files, risks, and dependencies.
