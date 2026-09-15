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
3. Prepare directly and cheaply, without delegating: use local inspection plus `get_current_plan`/`summarize_worktree` to gather the minimum evidence the contract needs. Do not invoke a planner merely because the task is non-trivial or spans files.
4. Decide whether a planner adds independent value — ambiguity, architecture, material risk, or a genuinely independent planning/investigation slice. File count, length, or difficulty alone is not a trigger. If it does not, skip to step 8.
5. If a planner is justified, present to the user in one message: the prepared brief, the selected planner profile (when profiles are available), and the exact model and thinking level that profile resolves to, including whether that model/thinking is currently available. Never invent a fallback profile and never silently change model, provider, or thinking defaults.
   - If the selected profile, its model, or its thinking level is unavailable, report exactly what is missing and ask how to proceed; do not fall back to another profile or to defaults.
6. Invoke `subagent` with the proposed profile/configuration and the prepared contract. Its host UI obtains the single model/thinking approval before launching a child, including when profile is omitted. Do not ask a duplicate approval question beforehand. No UI means no launch. Cancellation ends this attempt: report `Status: cancelled` and stop, without direct planning, another profile/role, or retry. Give the planner relevant evidence, not the raw conversation. The read-only planner returns one executable checklist; the coordinator alone persists and integrates it.
7. Integrate the planner output into the same canonical session-plan file. Preserve all material evidence and unresolved questions rather than summarizing them away; remove only true duplication.
8. Write one ordered, actionable checklist under `## Tasks` with top-level `- [ ] Tn: ...` IDs, exact files/symbols, dependencies, acceptance, checks, risks, and unresolved questions. Include `## TL;DR` for user orientation, not as a substitute for the contract/checklist. Use the small `## Current Step` format defined in the ops skill (Current/Next/Blockers); keep referenced IDs consistent with Tasks.
9. Persistence and read-back are mandatory before the final response: write the complete plan to the returned path, then re-read the entire file from disk (in bounded chunks/offsets if needed) and verify that every contract section and every material detail is present. Do not rely on a truncated preview. If persistence or verification fails, finish with `Status: blocked` rather than claiming the plan is complete.
10. Planning completion means the complete document has been persisted and read back, not that implementation or its test suite has run. Finish with `Status: complete`, `partial`, or `blocked`; report unresolved questions and risks rather than guessing. Once the full plan is persisted and verified, present only a brief delta to the user: goal, plan path, checklist summary, files, risks, and dependencies. Never show a detailed plan in chat while storing a minimal summary, and never treat a brief final response as a substitute for the file.
