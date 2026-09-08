---
name: ops
description: Memory management (.ai/), context engineering, and selective subagent orchestration.
---

# Ops: System Control and Memory

## 1. Memory Management (.ai/)

Use project-relative paths. The rule “do not write outside `.ai/`” applies to memory-management artifacts and tools (`.ai/MEMORY.md`, `.ai/TASKS.md`, session plans, and daily notes), not to the explicitly scoped project files of the current task.

- `create_session_plan(slug)`: use only when a non-trivial task genuinely needs a persisted plan; keep one plan per session.
- Record meaningful progress as a delta in the active plan. Do not call unavailable memory tools or create a second daily log by default.
- Update `MEMORY.md` only for stable lessons. Keep `TASKS.md` focused on pending work and link complex plans rather than copying them.

## 2. Context Engineering

Follow project rules, specifications, and source evidence in that order. Load only relevant files, ranges, skills, and documentation; reuse recorded evidence instead of rebuilding inventories or repeating plans. If rules and source conflict, stop and report the conflict.

## 3. Selective Orchestration

The principal is the authority and coordinator. Delegate only a bounded reasoning, read-only investigation, or implementation slice when isolation or genuine independence outweighs handoff and verification costs.

- Normally use **0–1** child; use at most **2** for genuinely independent, non-overlapping work.
- File count, “non-trivial,” or context anxiety alone is not a trigger.
- The principal supplies and validates the contract; children do not launch nested subagents. A missing dependency returns `blocked` with the exact question.
- Use local tools directly for deterministic reads, searches, transforms, tests, and decisions already supported by evidence.

Every brief uses: **Goal**, **Known**, **Evidence**, **Acceptance**, **Checks**, and **Stop**. Child output starts with **Status** (`complete`, `partial`, `blocked`, `failed`, `cancelled`, or `timed_out`) and reports only new findings/changes, evidence, checks, and unresolved items.

Validation policies for workers: `no-tests`, `targeted-check`, `add-test`, `test-first`, or `defer-validation`. Name the concrete command or reason; do not invent provider calls.

## 4. Direct Questions

Answer a direct conceptual question directly. Inspect files or use a child only when repository-specific evidence is required.

## 5. Clarification and Risk Gate

Do not ask for confirmation routinely. Ask one focused question when wording is materially ambiguous, interpretations diverge, or safety/data/production risk makes guessing unacceptable. For a clear, bounded, low-risk request, execute directly.

## 6. Critical Configuration Safety

Before editing critical local/system configuration, create a timestamped backup and explain the intended change. Critical files include `.env`, SSH, credentials, deployment/production, shell/profile, and database/client configuration. Do not edit them without explicit approval.

## 7. Loop Control

If two passes produce no new evidence, change strategy or stop. Do not retry the same failure twice without new evidence, and do not restate an existing route, decision, or inventory.
