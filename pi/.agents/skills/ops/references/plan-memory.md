# Plan Memory Contract

Use project-relative paths. `.ai/TASKS.md` holds pending problems/outcomes, with priority when useful; link complex work to its canonical plan, not a duplicate checklist/progress. `.ai/plan/` holds technical contracts and task acceptance; each worker brief carries one authorized task. The `.ai/` restriction covers memory artifacts (`MEMORY.md`, tasks, plans, daily notes), not implementation files.

## Persistence and selection

Persist for durable decisions, related phases, resumption or handoff—not merely proposals, file count or multiple steps. Outside `/plan`, do not routinely create or offer plans. `/plan` owns plan creation, its mandatory planner and approval gates.

- Reuse the active selection. Showing, serving, testing, or reviewing completed work continues its plan. Handle one-off follow-ups directly; append a task if tracking is useful. A new plan needs an independent goal or material scope change; compare the current goal/artifacts before `newPlan=true`, asking only if the distinction is unclear.
- `select_session_plan` is for explicit existing-file adoption/switch. It and `create_session_plan(newPlan=true)` obtain their own UI confirmation; do not ask again. Cancellation preserves the previous selection and ends the attempt. Selection never authorizes implementation.
- Resolve identity with `get_current_plan`, never newest-file heuristics. Selection follows the full active branch, including compacted metadata, not another branch. A blocked or missing selection is never silently recreated.
- At start/resume, read the selected Markdown contract, Current Step, next authorized task, acceptance, and validation. After compaction, reread only if retained context is insufficient; within a task reuse evidence. Recheck at task changes or material discrepancies, not before every call. `summarize_worktree` is the compact repo view.

## Canonical plan

Use the existing `## TL;DR`, `## Current Step`, and `## Tasks` structure with stable top-level `Tn` IDs. Under `## Tasks`, write unindented checklist items as `- [ ] T1: Observable outcome` (accepted: `- [x] T1: Observable outcome`); put supporting details beneath each item. This is the format recognized by the plan reader. Do not introduce another template or migrate old plans just to shorten them.

Current Step has three lines:

- `- Current: T1` (an existing task ID or `none`)
- `- Next: T2` (an existing task ID or `none`)
- `- Blockers: none` (or concise evidence)

An explicit nonexistent ID is an inconsistency, not permission to substitute a task. Keep old free-form steps readable.

Capture objective, constraints, behavior, material decisions/reasons, implemented-versus-verified work, pending checks, blockers and next action. Tasks are verifiable outcomes, not tool-call logs. Name exact files, symbols, dependencies, acceptance and checks where execution/verification needs them. Record actual checks; reference existing inventories rather than copying them.

Markdown is the sole editable plan source. The extension resolves selection and serves explicit reads; lifecycle events do not synchronize content into prompts. Do not call unavailable memory tools or create a second daily log by default. `MEMORY.md` holds only stable lessons; the backlog holds pending work.

## Revisions and evidence

When a user decision supersedes the design, reconcile TL;DR, task contract, acceptance, Current Step and blockers; mark earlier evidence historical rather than leaving contradictions active. Attribute user-confirmed checks with scope and timing, never as agent executions. Only the coordinator edits progress; workers return evidence, not plan updates. Preserve resumable evidence for partial, blocked, cancelled or timed-out work.
