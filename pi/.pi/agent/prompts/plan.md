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

Follow this order exactly:

1. Planning only: do not modify implementation files. Updating the session plan file is allowed.
2. Create or retrieve the plan first. For every non-trivial plan, call `create_session_plan` once and use the exact path it returns. The tool only creates a template: immediately populate that file with the complete plan. If a plan already exists, update that same active plan instead of creating a duplicate. Explicit adoption via `select_session_plan` or starting another via `newPlan=true` is confirmed by that tool's UI, not by another prompt question; cancel leaves the prior selection/documents unchanged and stops the attempt. Selection does not authorize implementation.
3. Prepare directly and cheaply, without delegating: use local inspection plus `get_current_plan`/`summarize_worktree` to gather the minimum evidence the contract needs. Preparation only gathers evidence; it does not author the plan.
4. The `planner` subagent is mandatory in this workflow. `/plan` exists precisely so the planner designs the plan; the selected model must not write the plan itself. Task size, difficulty, or apparent simplicity is never a reason to plan directly here. Never produce the checklist yourself as a substitute, and never treat the planner as optional because APPEND_SYSTEM permits skipping it elsewhere — simple work that does not deserve a plan should simply not use `/plan`.
5. Use `openai-codex/gpt-6.1-sol` with profile `low` by default. Use `medium` only when material dependencies, competing designs, or unresolved trade-offs need deeper reasoning; use `high` only for substantial architectural uncertainty or high-impact risk where medium is inadequate. State the concrete reason for either escalation; task length or file count alone is insufficient. An unavailable low selection is a blocker, not a reason to escalate. Present to the user in one message: the prepared brief, the selected planner profile (when profiles are available), and the exact model and thinking level that profile resolves to, including whether that model/thinking is currently available. Never invent a fallback profile and never silently change model, provider, or thinking defaults.
   - Always pass the same reason as the tool's `profileReason` argument, including for `low` (for example, no material dependencies). The approval dialog shows it as the coordinator's recommendation; the user can still choose another level there, and that choice is the one that launches.
   - If the selected profile, its model, or its thinking level is unavailable, report exactly what is missing and ask how to proceed; do not fall back to another profile or to defaults.
6. Invoke `subagent` with agent `planner`, the proposed profile, its `profileReason`, and the prepared contract. Its host UI obtains the single model/thinking approval before launching a child, including when profile is omitted. That dialog lists every available level, marks yours as recommended with your reason, and starts a child only for the level the user actually selects. Do not ask a duplicate approval question beforehand. No UI means no launch. Cancellation ends this attempt: report `Status: cancelled` and stop, without direct planning, another profile/role, or retry. Give the planner relevant evidence, not the raw conversation. The read-only planner returns one executable checklist; the coordinator alone persists and integrates it.
7. Integrate the planner output into the same canonical session-plan file, preserving its checklist and ordering as the plan's substance. Preserve all material evidence and unresolved questions rather than summarizing them away; remove only true duplication. If the planner returns `partial` or `blocked`, keep its unresolved items visible instead of filling the gaps by planning them yourself; report the corresponding status.
8. Write one ordered, actionable checklist under `## Tasks` with top-level `- [ ] Tn: ...` IDs, exact files/symbols, dependencies, acceptance, checks, risks, and unresolved questions. Include `## TL;DR` for user orientation, not as a substitute for the contract/checklist. Use the small `## Current Step` format defined in the ops skill (Current/Next/Blockers); keep referenced IDs consistent with Tasks.
9. Persistence and read-back are mandatory before the final response: write the complete plan to the returned path, then re-read the entire file from disk (in bounded chunks/offsets if needed) and verify that every contract section and every material detail is present. Do not rely on a truncated preview. If persistence or verification fails, finish with `Status: blocked` rather than claiming the plan is complete.
10. Follow APPEND_SYSTEM's human-facing communication rule throughout planning, including blockers and resumptions. Planning completion means the complete document has been persisted and read back, not that implementation or its test suite has run. Finish with `Status: complete`, `partial`, or `blocked`. After verification, explain the proposal **for the person deciding whether to proceed**, in plain language rather than reproducing the executor's checklist:
   - **What will change and why**: the intended outcome and the main changes, grouped by effect rather than by file or task ID.
   - **What it implies**: visible behavior, migration or compatibility effects, dependencies, and what remains untouched, where relevant.
   - **Complications or decisions**: material risks, trade-offs, open questions, and blockers; say when there are none known rather than inventing them.
   Include the plan path as a reference at the end, not as the answer itself. Scale the summary to the task: a few sentences for a simple plan, short sections for a complex one. Do not dump the full technical plan into chat or hide its substance behind a link. Preserve the full actionable contract in the file, and never present planning as implementation or validated tests.
