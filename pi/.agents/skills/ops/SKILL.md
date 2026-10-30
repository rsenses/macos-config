---
name: ops
description: "Use before implementing, delegating work, or reporting implementation readiness; also when managing .ai/ plans and tasks, resuming saved work, coordinating subagents, or deciding validation scope and approval boundaries."
---

# Ops: System Control and Memory

## 1. Memory Management (.ai/)

Use project-relative paths. `.ai/TASKS.md` holds pending problems/outcomes, with priority when useful; link complex work to its canonical plan, not a duplicate checklist/progress. `.ai/plan/` holds technical contracts and task acceptance; each worker brief carries one authorized task. The `.ai/` restriction covers memory artifacts (`MEMORY.md`, tasks, plans, daily notes), not implementation files.

### Persistence and selection

Persist for durable decisions, related phases, resumption or handoff—not merely proposals, file count or multiple steps. Outside `/plan`, do not routinely create or offer plans. `/plan` requires persistence, its planner and approval gates.

- Reuse the active selection. Showing, serving, testing, or reviewing completed work continues its plan. Handle one-off follow-ups directly; append a task if tracking is useful. A new plan needs an independent goal or material scope change; compare the current goal/artifacts before `newPlan=true`, asking only if the distinction is unclear.
- `select_session_plan` is for explicit existing-file adoption/switch. It and `create_session_plan(newPlan=true)` obtain their own UI confirmation; do not ask again. Cancellation preserves the previous selection and ends the attempt. Selection never authorizes implementation.
- Resolve identity with `get_current_plan`, never newest-file heuristics. Selection follows the full active branch, including compacted metadata, not another branch. A blocked or missing selection is never silently recreated.
- At start/resume, read the selected Markdown contract, Current Step, next authorized task, acceptance, and validation. After compaction, reread only if retained context is insufficient; within a task reuse evidence. Recheck at task changes or material discrepancies, not before every call. `summarize_worktree` is the compact repo view.

### Canonical plan

Use the existing `## TL;DR`, `## Current Step`, and `## Tasks` structure with stable top-level `Tn` IDs. Under `## Tasks`, write unindented checklist items as `- [ ] T1: Observable outcome` (accepted: `- [x] T1: Observable outcome`); put supporting details beneath each item. This is the format recognized by the plan reader. Do not introduce another template or migrate old plans just to shorten them.

Current Step has three lines:

- `- Current: T1` (an existing task ID or `none`)
- `- Next: T2` (an existing task ID or `none`)
- `- Blockers: none` (or concise evidence)

An explicit nonexistent ID is an inconsistency, not permission to substitute a task. Keep old free-form steps readable.

Capture objective, constraints, behavior, material decisions/reasons, implemented-versus-verified work, pending checks, blockers and next action. Tasks are verifiable outcomes, not tool-call logs. Name exact files, symbols, dependencies, acceptance and checks where execution/verification needs them. Record actual checks; reference existing inventories rather than copying them.

Before the read-only planner returns its design, record only the brief and evidence. The coordinator then saves and reads back the complete proposal. Preserve partial/blocked results and unresolved questions; do not design missing pieces yourself. Persistence/read-back failure blocks planning completion.

Present all proposed tasks in chat as a concise numbered list in execution order, retaining Tn IDs. For each show the title, observable delivery and dependencies (or none). Invite the user to confirm or add, remove, merge, split or reorder tasks before implementation; record adjustments in the same plan under the existing revision rules. This proposal exchange adds no approval gate; implementation authorization remains separate.

### Progress and handoff

When a user decision supersedes the design, reconcile TL;DR, task contract, acceptance, Current Step and blockers; mark earlier evidence historical rather than leaving contradictions active. Attribute user-confirmed checks with scope and timing, never as agent executions.

Only the coordinator writes progress after verifying acceptance: check accepted tasks and update Current Step, concise evidence, checks/results and blockers. Child success is not acceptance; routine updates need no planner. Preserve resumable evidence for partial/blocked/cancelled/timed-out work; on resume, skip only still-valid acceptance and recheck stale evidence.

Assign each worker one bounded task, plan path/task ID and the section 3 brief; stop after that task, never advance autonomously through the plan. Before the next dependent task, the coordinator inspects the diff for scope and smallest sufficient change, verifies acceptance with permitted checks and records the result. Parallelize only independent tasks expressly permitted by the plan, within section 3's limits, without overlapping writes or checks requiring a stable tree.

Markdown is the sole editable plan source. The extension resolves selection and serves explicit reads; lifecycle events do not synchronize content into prompts. Do not call unavailable memory tools or create a second daily log by default. `MEMORY.md` holds only stable lessons; the backlog holds pending work.

## 2. Context Engineering

Load relevant project rules, source ranges, and versioned contracts. Keep changing state out of reusable system/tool prefixes; append explicit results instead. APPEND_SYSTEM governs evidence reuse and bounded tool output.

When a clear contract conflicts with code, investigate and fix within scope. If competing rules make intended behavior undecidable, report the exact conflict and ask before changing it.

## 3. Selective Delegation

The principal owns scope, decisions, integration and final validation. Delegate only when specialization, isolation or independently verifiable work outweighs briefing/integration overhead—not mere separability or file count.

- Normally use zero or one child, at most two genuinely independent, non-overlapping tasks. Do not manufacture work to fill a quota.
- Handle direct questions, trivial lookups, and indivisible edits locally without routinely explaining why no child was used.
- `/plan` requires a planner design; preparation gathers evidence without pre-solving it. Elsewhere use a planner for material alternatives, not routine status updates.
- Children cannot delegate. Missing material prerequisites return `blocked` with the exact question. Use direct tools for orientation, deterministic operations, and final validation.
- `plan-reviewer` is manual-only: invoke it only when explicitly requested for a saved plan or through `/review-plan`, never automatically from architect, planner, `/plan`, or `/run-plan`.
- `code-reviewer` is manual-only: invoke it through `subagent` only when the user explicitly requests that agent to review an existing implementation. It is not a post-worker, pre-test, `/run-plan`, planning, acceptance, or task-closing stage. Supply the original request, clarifications, decisions, current contract/plan if any, scoped diff, and readable project/skill references in the existing brief. Its recommendations do not authorize fixes or change the current validation policy.

### Brief and output contracts

Every brief uses these headings:

- **Goal**: bounded outcome/scope and write permissions.
- **Known**: decisions, constraints, invariants, and existing changes to preserve.
- **Evidence**: checked paths/ranges/URLs or excerpts, plus the remaining unknown.
- **Acceptance**: observable result, including security and applicable changelog requirements.
- **Checks**: concrete permitted checks; never invent provider calls.
- **Stop**: ambiguity, scope conflict, missing evidence, or repeated failure without new evidence.

Pass established evidence, the remaining question, original request and later clarifications—not a transcript, rediscovery request or only the plan/implementer's account. Separate decisions, verified facts and assumptions in Known/Evidence. Children run with `--no-skills`: put relevant skill criteria in Known as short excerpts, or exact readable paths/sections with explicit read instructions when needed. Prefer sufficient excerpts; do not require full-skill reads for trivial work. Request concise evidence but complete actionable planning designs; integrate each locally verified result once into the canonical plan, without duplicate reports.

Child output starts with **Status** (`complete`, `partial`, `blocked`, `failed`, `cancelled`, `timed_out`), then its role's findings/changes, evidence, checks, and unresolved items. Workers return **Status / Changes / Evidence / Checks / Unresolved**. Name their validation policy (`no-tests`, `targeted-check`, `add-test`, `test-first`, `defer-validation`) and the concrete command or reason.

### Assessing review findings

Assess findings against the user's request/clarifications, current contract, then implementation. Verify evidence and materially affected consumers. A plan/implementer's account alone does not establish acceptance; disagreement or model authority does not decide a finding.

Use these distinctions in the existing handoff; no empty sections or finding quota:

- **Supported defect**: concrete evidence, observable impact, and the smallest justified correction.
- **Pending hypothesis**: the missing fact and minimum check, including what result would confirm or refute it. Do not report proposed execution or browser checks as performed.
- **Optional improvement**: outside acceptance requirements; keep separate from required corrections.
- **Dismissed finding**: give the concrete reason when communicating the dismissal matters.

Apply justified corrections within scope. Reject preferences and abstractions without demonstrated benefit; consult the user for changes to intent or scope. For PHP/Laravel, use `laravel-simplicity` rather than class, layer, or consumer counts; one implementation does not invalidate an abstraction.

Use the initial review; add a focused correction check only when substantive corrections warrant it; no indefinite rounds, extra judge or routine model call. No findings is valid; partial coverage is not full approval. This adds no stage, permission or validation policy.

### Approval boundaries

The launcher approves planner model/thinking once, showing `profileReason`; the user may choose another available profile. Selection tools confirm adoption or `newPlan=true`; implementation still needs separate user authorization. Never duplicate UI questions. Cancellation ends the attempt without retry/fallback; report unavailable profiles, models, or thinking instead of silently changing them. Keep principal model/provider/thinking/settings unchanged unless explicitly requested.

In `/run-plan`, obtain implementation approval once through the question tool/UI before any worker or implementation. Only after approval set `in-progress` and record the current task; execute task by task under section 1. Cancellation preserves the plan and ends the attempt.

## 4. Validation reporting

Run full project validation (fix/format/lint, then tests) only on explicit user request, using project-specific commands under APPEND_SYSTEM's policy. A user's own run may be recorded as user-confirmed evidence, with scope and timing, never as an agent execution or authorization to rerun it. Never require the suite as a gate before other work.

Any implementation status report states which checks ran (command, exit result, notable output) and which did not. Targeted checks, dry runs, and child success are reported as targeted, never as full validation. Do not say tests pass or that work is ready to ship unless the relevant checks ran and succeeded; name the unverified remainder instead.

Planning, read-only review, and worker slices use their scoped checks.

## 5. Direct Questions

Answer conceptual questions directly; gather repository-specific evidence only when needed, within section 3's delegation limits.

## 6. Clarification and Risk Gate

Before consolidating a materially ambiguous interpretation, state the outcome, invariants and open decision under APPEND_SYSTEM's communication rule, not a second specification/approval step. Distinguish decisions, facts and assumptions; do not invent missing intent.

Ask one focused question for material ambiguity, preference or safety/data/production risk; otherwise execute authorized bounded work without routine confirmation or restating clear requests. Apply section 3's approval gates once.

`/sharpen` manually reformulates a request using the brief in section 3; `/grill-me` supports clarification through conversation when needed; `/plan` designs and persists a plan through its existing planner flow. Do not chain them automatically. Deepening a brief does not expand its scope: separate unrequested improvements as optional. Direct work needs none of these commands as a prerequisite.

## 7. Critical Configuration Safety

Before editing critical local/system configuration, create a timestamped backup and explain the intended change. This includes `.env`, SSH, credentials, deployment/production, shell/profile, and database/client configuration. Explicit approval is required.

## 8. Loop Control

After two attempts without new evidence, change strategy or stop. Do not repeat the same failure twice without new evidence or restate a known route, decision, or inventory.
