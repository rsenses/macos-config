---
description: Create a risk-aware implementation plan with the planner
argument-hint: "<task>"
---

Plan for: $ARGUMENTS

Load `ops` for shared policies and the canonical brief; read `~/.agents/skills/ops/references/plan-memory.md` for selection, format and revisions. Use `architect` for design criteria. Planning only: implementation files are read-only.

1. Call `create_session_plan` once and use its exact path, reusing the active selection. Any adoption/new-plan confirmation belongs to the selection UI. Cancellation ends the attempt; selection is not implementation approval.
2. Gather minimal local evidence for the Goal/Known/Evidence/Acceptance/Checks/Stop brief. Include applicable `architect` criteria, the acceptance criteria in step 4 and a readable path to the shared plan-memory contract in Known under ops' selective skill-handoff rule. Before delegation, save only the brief, user decisions, existing changes and unresolved questions—not a full architecture survey or pre-written solution.
3. Invoke `subagent` with `agent: "planner"`: mandatory even for simple requests in this command. Use the tool's advertised `low` profile by default; recommend `medium` for material dependencies/trade-offs, or `high` only for uncertainty/risk that medium cannot address. Supply a concrete `profileReason` for every recommendation, not file count or length. Present the suggested exact model/thinking and availability; the launcher obtains the single approval. No UI, cancellation, or unavailable selections permit fallback, another role, or direct planning.
4. Integrate the child's design into the same document, preserving order, material decisions/evidence, unresolved items and execution detail. Acceptance must name the observable user workflow or operational outcome, required environment and evidence. Distinguish synthetic checks from real integrations; working components alone do not establish an end-to-end outcome. Unresolved acceptance gaps remain explicit, not invented by the coordinator. Remove duplication; do not draft a competing solution or fill partial/blocked design gaps.
5. Save in the shared plan-memory format and read back the entire file (chunk if needed). Verify task IDs, dependencies, acceptance, checks, risks and pending work. Previews are insufficient; save/read-back failure is blocked.
6. Present all proposed tasks as a concise numbered list in execution order with stable Tn IDs, title, observable delivery and dependencies (or none). Invite the user to confirm or add, remove, merge, split or reorder tasks; record adjustments in the same plan. This exchange adds no approval gate; implementation authorization remains separate. Explain why the proposal matters, material implications, and remaining decisions in the user's language. Distinguish complete/partial/blocked planning from implementation; append the plan path as a reference. No implementation or application test success is implied.
