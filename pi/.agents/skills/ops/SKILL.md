---
name: ops
description: Memory management (.ai/), context engineering, and default subagent orchestration.
---

# Ops: System Control and Memory

## 1. Memory Management (.ai/)

Use project-relative paths. The rule “do not write outside `.ai/`” applies to memory-management artifacts and tools (`.ai/MEMORY.md`, `.ai/TASKS.md`, session plans, and daily notes), not to the explicitly scoped project files of the current task.

- `create_session_plan(slug)`: use only when a non-trivial task genuinely needs a persisted plan; reuse the active selection. `select_session_plan(path)` and `create_session_plan(slug, newPlan=true)` obtain confirmation in their own UI before changing selection; do not duplicate that question. Cancel/abort preserves prior state and ends the attempt. Selection belongs to the full active branch, not compacted context or other branches, and does not authorize implementation.
- The coordinator saves and updates the canonical plan; planner remains read-only. Include `## TL;DR` for user orientation without replacing the contract/checklist. Under `## Tasks`, use top-level `- [ ] T1: ...` / `- [x] T1: ...` with stable IDs; nest evidence, dependencies, acceptance and checks under their task. Open tasks may carry `pending`, `in-progress` or `blocked` in their text; check only accepted tasks.
- `## Current Step` contains three lines: `- Current: T1` (current task ID or `none`), `- Next: T2` (next task ID or `none`), `- Blockers: none` (or concise blocking evidence). IDs must exist in Tasks; Next and Blockers never select the current task. The reader tolerates old free-form steps and uses the first open task only when no current ID is supplied; a nonexistent explicit ID is an inconsistency to resolve, not permission to substitute a task.
- Record meaningful progress as a delta in the active plan. Do not call unavailable memory tools or create a second daily log by default.
- Update `MEMORY.md` only for stable lessons. Keep `TASKS.md` focused on pending work and link complex plans rather than copying them.

## 2. Context Engineering

Follow project rules, specifications, and source evidence in that order. Load only relevant files, ranges, skills, and documentation; reuse recorded evidence instead of rebuilding inventories or repeating plans. If rules and source conflict, stop and report the conflict.

## 3. Delegation by Default

The principal is the authority and coordinator. Unless the user asks otherwise, delegate a bounded `scout` investigation or `worker` implementation whenever the task has a separable, useful slice. Prefer `scout` early in open-ended repository diagnosis and `worker` for independently checkable changes with explicit write scope; retain integration and full-project validation with the principal.

- Normally use **1** child for a delegable task; use at most **2** for genuinely independent, non-overlapping work. Do not invent work to meet a quota.
- Answer direct questions, do trivial lookups and make indivisible surgical edits locally. File count, “non-trivial,” or context anxiety alone is not a trigger. If a clear slice stays local, briefly say why; reassess when new evidence exposes a separable slice.
- The principal supplies and validates the contract; children do not launch nested subagents. A missing dependency returns `blocked` with the exact question.
- Use local tools directly for orientation, deterministic operations, and final validation.

Every brief uses: **Goal**, **Known**, **Evidence**, **Acceptance**, **Checks**, and **Stop**. Child output starts with **Status** (`complete`, `partial`, `blocked`, `failed`, `cancelled`, or `timed_out`) and reports only new findings/changes, evidence, checks, and unresolved items.

Validation policies for workers: `no-tests`, `targeted-check`, `add-test`, `test-first`, or `defer-validation`. Name the concrete command or reason; do not invent provider calls.

## 4. Full validation as a completion invariant

Overall IMPLEMENTATION readiness requires the principal to run authoritative full-project validation from the project root. Finishing a planning document instead requires persistence and full read-back; a read-only review requires its inspection checks; a worker slice requires its authorized checks. These bounded outcomes do not certify application readiness. Run complete fix/format/lint commands before complete tests; for documented Laravel/PHP projects this is exactly `composer fix` then `composer test`, with no narrowing flags or targeted substitutes. Targeted worker checks remain useful for slice acceptance but never certify overall readiness. Record the actual command, natural-completion/exit result, fixer changes, and every skip or failure in the plan. If the implementation gate is not fully successful, preserve the evidence and mark implementation `partial`/`blocked`; report `not ready to ship`, never “tests pass”.

## 5. Direct Questions

Answer a direct conceptual question directly. Inspect files or use a child only when repository-specific evidence is required.

## 6. Clarification and Risk Gate

Do not ask for confirmation routinely. Preserve the specific workflow approvals in APPEND_SYSTEM (planner launch, plan selection and implementation authorization), using each gate once. Ask one focused question for material ambiguity or safety/data/production risk. Otherwise execute ordinary steps of an authorized bounded request directly.

## 7. Critical Configuration Safety

Before editing critical local/system configuration, create a timestamped backup and explain the intended change. Critical files include `.env`, SSH, credentials, deployment/production, shell/profile, and database/client configuration. Do not edit them without explicit approval.

## 8. Loop Control

If two passes produce no new evidence, change strategy or stop. Do not retry the same failure twice without new evidence, and do not restate an existing route, decision, or inventory.
