---
name: ops
description: "Use before implementing, delegating work, or reporting implementation readiness; also when managing .ai/ plans and tasks, resuming saved work, coordinating subagents, or deciding validation scope and approval boundaries."
---

# Ops: System Control and Memory

## 1. Memory Management (.ai/)

Use project-relative paths. The restriction to `.ai/` applies to memory artifacts (`MEMORY.md`, `TASKS.md`, plans, daily notes), not authorized implementation files.

### Persistence and selection

Persist a plan when durable decisions, related phases, resumption or handoff need it. Explaining proposals, file count or multiple steps alone do not require persistence. Outside `/plan`, do not routinely create or offer a plan. `/plan` requires persistence, its planner and approval gates.

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

Capture objective, constraints, behavior, material decisions/reasons, implemented-versus-verified work, pending checks, blockers, and next action. Tasks are verifiable outcomes, not a log of tool calls. Include exact files, symbols, dependencies, acceptance, and checks only when execution or verification needs them. Record checks actually run; refer to existing inventories instead of copying them.

Before a planner returns, record only the brief and evidence. The planner is read-only; it supplies the design, then the coordinator saves the complete proposal and reads it back in full. Preserve partial/blocked results and unresolved questions rather than designing missing pieces yourself. Persistence or read-back failure is blocked, not completed planning.

### Progress and handoff

When a later user decision supersedes the design, consolidate the current TL;DR, task contract, acceptance, Current Step, and blockers. Preserve earlier evidence as explicitly historical; do not leave contradictory instructions active. Record user-confirmed checks as user-confirmed, with their scope and timing, not as checks the agent ran.

Only the coordinator writes progress after verifying acceptance: check accepted tasks and update Current Step, concise evidence, checks/results and blockers. Child success is not acceptance; routine updates need no planner.

Assign each worker one bounded task, plan path/task ID and the section 3 brief: writable files, established decisions, permitted checks and a stop after that task. Never assign the remaining plan or autonomous advancement. Before assigning the next dependent task, the coordinator inspects the diff for scope and smallest sufficient change, verifies acceptance with permitted checks and records the result. Parallelize independent tasks only with express plan permission and section 3's limits. Do not pass the full plan/conversation by default; integrate each result once after local verification.

Markdown is the sole editable source of plan content. The extension resolves selection and serves explicit reads; lifecycle events do not synchronize document contents into prompts. Do not call unavailable memory tools or create a second daily log by default. Put only stable lessons in `MEMORY.md`; keep `TASKS.md` focused on pending work and link complex plans.

## 2. Context Engineering

Load relevant project rules, source ranges, and versioned contracts; reuse evidence. Minimize total tokens needed for a verified outcome, not merely one request. Bound/filter tool output before it enters context; recover only needed ranges. Keep changing state out of reusable system/tool prefixes and append explicit results instead.

When a clear contract conflicts with code, investigate and fix within scope. If competing rules make intended behavior undecidable, report the exact conflict and ask before changing it.

## 3. Selective Delegation

The principal owns scope, decisions, integration, and final validation. Delegate only when specialization, isolation, or independently verifiable work outweighs briefing and integration overhead; separability or file count alone is insufficient.

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

Pass established evidence and the remaining question, not a transcript or a request to rediscover facts. Separate user decisions, verified facts, and assumptions in Known/Evidence. Include the relevant request and later clarifications, not just the plan or implementer's explanation. Supply readable paths to applicable skills and references; children do not inherit the principal's loaded skills. Request concise evidence, but preserve the complete actionable design when planning. Keep one canonical plan; integrate results once instead of copying reports across artifacts and chat.

Child output starts with **Status** (`complete`, `partial`, `blocked`, `failed`, `cancelled`, `timed_out`), then its role's findings/changes, evidence, checks, and unresolved items. Workers return **Status / Changes / Evidence / Checks / Unresolved**. Name their validation policy (`no-tests`, `targeted-check`, `add-test`, `test-first`, `defer-validation`) and the concrete command or reason.

### Assessing review findings

Assess existing review findings against the user's request/clarifications, current contract, then implementation—in that order. Verify cited evidence and materially affected consumers. A plan or implementer's explanation alone does not establish acceptance; neither disagreement with the implementer nor model authority decides a finding.

Use these distinctions within the existing handoff, without requiring empty sections or a finding quota:

- **Supported defect**: concrete evidence, observable impact, and the smallest justified correction.
- **Pending hypothesis**: the missing fact and minimum check, including what result would confirm or refute it. Do not report proposed execution or browser checks as performed.
- **Optional improvement**: outside acceptance requirements; keep separate from required corrections.
- **Dismissed finding**: give the concrete reason when communicating the dismissal matters.

Apply justified corrections within scope. Reject preferences and abstractions without demonstrated benefit; consult the user for changes to intent or scope. For PHP/Laravel, use `laravel-simplicity` rather than class, layer, or consumer counts; one implementation does not invalidate an abstraction.

Use the initial review and, when substantive corrections warrant it, a focused correction check; no indefinite rounds, extra judge or routine model call. No findings is valid; partial coverage is not full approval. This interprets existing reviews, not a new stage, permission or validation policy.

### Approval boundaries

The launcher approves planner model/thinking once, showing `profileReason`; the user may choose another available profile. Selection tools confirm adoption or `newPlan=true`; implementation still needs separate user authorization. Never duplicate UI questions. Cancellation ends the attempt without retry/fallback; report unavailable profiles, models, or thinking instead of silently changing them. Keep principal model/provider/thinking/settings unchanged unless explicitly requested.

## 4. Validation reporting

Full project validation (for documented Laravel/PHP projects: `composer fix`, then `composer test`, from the project root) runs only when the user explicitly requests it or runs it themselves. The agent does not run it or require it as a gate before other work.

Any implementation status report states which checks ran (command, exit result, notable output) and which did not. Targeted checks, dry runs, and child success are reported as targeted, never as full validation. Do not say tests pass or that work is ready to ship unless the relevant checks ran and succeeded; name the unverified remainder instead.

Planning, read-only review, and worker slices use their scoped checks. Changelog entries follow APPEND_SYSTEM's Changelog Policy.

## 5. Direct Questions

Answer conceptual questions directly. Inspect files or delegate only when repository-specific evidence is needed, using the smallest useful lookup.

## 6. Clarification and Risk Gate

When material ambiguity could change behavior, briefly state the understood outcome, what must remain unchanged, and any open decision before that interpretation is consolidated in a plan or implementation. Use APPEND_SYSTEM's existing communication rule, not a second specification or approval step. Distinguish user decisions, verified facts, and assumptions; do not invent a solution to fill a material gap.

Ask one focused question for material ambiguity, preference or safety/data/production risk; otherwise execute authorized bounded work without routine confirmation or restating clear requests. Apply APPEND_SYSTEM's workflow gates once, without repeating launcher, selection or implementation approvals.

`/sharpen` manually reformulates a request using the brief in section 3; `/grill-me` supports clarification through conversation when needed; `/plan` designs and persists a plan through its existing planner flow. Do not chain them automatically. Deepening a brief does not expand its scope: separate unrequested improvements as optional. Direct work needs none of these commands as a prerequisite.

## 7. Critical Configuration Safety

Before editing critical local/system configuration, create a timestamped backup and explain the intended change. This includes `.env`, SSH, credentials, deployment/production, shell/profile, and database/client configuration. Explicit approval is required.

## 8. Loop Control

After two attempts without new evidence, change strategy or stop. Do not repeat the same failure twice without new evidence or restate a known route, decision, or inventory.
