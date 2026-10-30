---
description: Create a risk-aware implementation plan with the planner
argument-hint: "<task>"
---

Plan for: $ARGUMENTS

Load `ops` for the canonical brief, plan format, selection, and approvals; use `architect` for design criteria. Planning only: implementation files are read-only.

1. Call `create_session_plan` once and use its exact path, reusing the active selection. Any adoption/new-plan confirmation belongs to the selection UI. Cancellation ends the attempt; selection is not implementation approval.
2. Gather minimal local evidence for the Goal/Known/Evidence/Acceptance/Checks/Stop brief. Include applicable `architect` criteria in Known under ops' selective skill-handoff rule. Before delegation, save only the brief, user decisions, existing changes and unresolved questions—not a full architecture survey or pre-written solution.
3. Invoke `subagent` with `agent: "planner"`: mandatory even for simple requests in this command. Use the tool's advertised `low` profile by default; recommend `medium` for material dependencies/trade-offs, or `high` only for uncertainty/risk that medium cannot address. Supply a concrete `profileReason` for every recommendation, not file count or length. Present the suggested exact model/thinking and availability; the launcher obtains the single approval. No UI, cancellation, or unavailable selections permit fallback, another role, or direct planning.
4. Integrate the child's design into the same document, preserving order, material decisions/evidence, unresolved items and execution detail. Remove duplication; do not draft a competing solution or fill partial/blocked design gaps.
5. Save in canonical ops format and read back the entire file (chunk if needed). Verify task IDs, dependencies, acceptance, checks, risks and pending work. Previews are insufficient; save/read-back failure is blocked.
6. Present the ordered task summary and invite adjustments under ops' proposal-presentation contract. Explain why the proposal matters, material implications, and remaining decisions in the user's language. Distinguish complete/partial/blocked planning from implementation; append the plan path as a reference. No implementation or application test success is implied.
