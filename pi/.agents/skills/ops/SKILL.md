---
name: ops
description: Memory management (.ai/), context engineering, selective subagent coordination, and implementation validation.
---

# Ops: System Control and Memory

## 1. Memory Management (.ai/)

Use project-relative paths. The rule “do not write outside `.ai/`” applies to memory-management artifacts and tools (`.ai/MEMORY.md`, `.ai/TASKS.md`, session plans, and daily notes), not to the explicitly scoped project files of the current task.

- `create_session_plan(slug)`: use only when a non-trivial task genuinely needs a persisted plan; reuse the active selection. `select_session_plan(path)` and `create_session_plan(slug, newPlan=true)` obtain confirmation in their own UI before changing selection; do not duplicate that question. Cancel/abort preserves prior state and ends the attempt. Selection belongs to the full active branch, not compacted context or other branches, and does not authorize implementation.
- The coordinator saves and updates the canonical plan; planner remains read-only. Include `## TL;DR` for user orientation without replacing the contract/checklist. Under `## Tasks`, use top-level `- [ ] T1: ...` / `- [x] T1: ...` with stable IDs; nest evidence, dependencies, acceptance and checks under their task. Open tasks may carry `pending`, `in-progress` or `blocked` in their text; check only accepted tasks.
- `## Current Step` contains three lines: `- Current: T1` (current task ID or `none`), `- Next: T2` (next task ID or `none`), `- Blockers: none` (or concise blocking evidence). IDs must exist in Tasks. The reader tolerates old free-form steps; a nonexistent explicit ID is an inconsistency to resolve, not permission to substitute a task.
- Before the planner returns, record only the brief and evidence in the identified document, not a pre-written implementation plan. Afterwards persist the complete proposal and read it back; retain unresolved items instead of guessing their resolution.
- Record meaningful progress as a delta in the active plan. Do not call unavailable memory tools or create a second daily log by default.
- Update `MEMORY.md` only for stable lessons. Keep `TASKS.md` focused on pending work and link complex plans rather than copying them.

## 2. Context Engineering

Load relevant project rules, specifications, source ranges, and documentation; reuse recorded evidence rather than rebuilding inventories. If expected behavior is clear and source code violates it, investigate and correct that violation within the authorized scope. If competing rules or unclear intent leave the expected behavior undecidable, report the exact conflict and ask before changing behavior.

## 3. Selective Delegation

The principal owns scope, decisions, integration, and final validation. Use a bounded `scout` investigation, `worker` implementation, or `researcher` inquiry when its specialization, context isolation, or independence offers a concrete benefit over direct work. Separability alone does not justify the overhead.

- Normally use zero or one child; use at most two for genuinely independent, non-overlapping work. Do not invent work to meet a quota.
- Answer direct questions, do trivial lookups, and make indivisible surgical edits locally. No routine explanation for not delegating is required.
- `/plan` always uses `planner` for the design; the principal gathers evidence, integrates, and persists, without drafting a competing plan first. Elsewhere use a planner when a material design decision warrants one, not for changing task status or recording checks.
- Children cannot delegate. Supply the contract and relevant evidence; a missing material prerequisite returns `blocked` with the exact question.
- Use local tools directly for orientation, deterministic operations, and final validation.

Every brief uses these headings:

- **Goal**: bounded outcome and scope, including write permissions when relevant.
- **Known**: facts, decisions, invariants, and existing changes to preserve.
- **Evidence**: exact paths, ranges, URLs, or excerpts already checked, and what remains unknown.
- **Acceptance**: observable result, including security and applicable changelog requirements.
- **Checks**: specific local checks the child may run; never invent provider calls.
- **Stop**: ambiguity, scope conflict, missing evidence, or repeated failure without new evidence.

Child output starts with **Status** (`complete`, `partial`, `blocked`, `failed`, `cancelled`, or `timed_out`), then follows its role's output contract with relevant findings or changes, evidence, checks, and unresolved items. Worker validation policies are `no-tests`, `targeted-check`, `add-test`, `test-first`, or `defer-validation`; name the concrete command or reason.

### Context budget

- Pass established evidence and the remaining question, not a raw transcript or a request to rediscover everything.
- Request concise evidence rather than complete source files or documentation. A planner still returns the complete actionable proposal needed for its requested scope; brevity must not remove material decisions, dependencies, or checks.
- Keep one canonical plan. Integrate relevant results once; avoid copying child reports into multiple documents and then repeating them in chat.
- Do not repeat a lookup whose evidence is already known; pass the delta and references.

### Manual-only plan reviewer

`plan-reviewer` is user-invoked. Dispatch it only when the user explicitly requests a saved-plan review or invokes `/review-plan`, never automatically from architect, planner, `/plan`, `/run-plan`, or `/finalize`.

## 4. Full validation as a completion invariant

This section defines overall IMPLEMENTATION readiness. A saved plan requires persistence and full read-back, a read-only review its inspection checks, and a worker slice its authorized checks. Those outcomes do not certify application readiness or require the application suite merely to finish a plan or review.

Before claiming overall implementation readiness:

1. Discover the authoritative full-project validation commands from project instructions and scripts. Apply required changelog edits according to APPEND_SYSTEM's Changelog Policy before final validation.
2. From the project root, run complete fix/format/lint commands, then complete tests. For Laravel/PHP projects documenting them, this is exactly `composer fix` followed by exactly `composer test`. No file filters, test selectors, dry runs, or targeted substitutes satisfy this gate.
3. Count only commands that actually reach natural completion and exit successfully. Partial output, timeouts, interruptions, child success, and unrun commands are not passing validation. Inspect fixer-produced changes and validate the post-fix tree with the full test suite.
4. If a required command is unsafe, unavailable, missing, skipped, interrupted, timed out, or failing, preserve the evidence, mark implementation `partial`/`blocked`, and report `not ready to ship` with the exact reason. Do not execute unsafe commands just to satisfy the gate or broaden the task to fix unrelated failures. User acceptance of a limitation does not make an unrun check pass.
5. Record commands, exit results, fixer-produced changes, skips, and unresolved failures in the plan or completion report. Distinguish a successful targeted check from the complete test command; only the latter supports a claim that the project's tests passed.

Targeted checks remain useful during development and for worker acceptance. They do not waive this final gate.

## 5. Direct Questions

Answer conceptual questions directly. Inspect files or use a child only when the answer needs repository-specific evidence, choosing the smallest useful lookup.

## 6. Clarification and Risk Gate

Do not ask for confirmation routinely. Preserve APPEND_SYSTEM's specific workflow approvals for planner launch, plan selection, and implementation, using each gate once. Ask one focused question for material ambiguity or safety/data/production risk. Otherwise execute ordinary steps of an authorized bounded request directly.

## 7. Critical Configuration Safety

Before editing critical local/system configuration, create a timestamped backup and explain the intended change. Critical files include `.env`, SSH, credentials, deployment/production, shell/profile, and database/client configuration. Do not edit them without explicit approval.

## 8. Loop Control

If two passes produce no new evidence, change strategy or stop. Do not retry the same failure twice without new evidence, and do not restate an existing route, decision, or inventory.
