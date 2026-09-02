# Plan: remove-project-memory
- Status: completed
- Created: 2026-08-30
- Session ID: 01a0531c

## Goal

Remove the durable project-memory layer because Laravel rules are the source of truth, while retaining task tracking and session plans.

## Current Step

Implementation and targeted validation completed.

## Spec / Contract

- `.ai/MEMORY.md` is no longer created, read, or injected.
- The `memory.ts` extension retains `TASKS.md` and session-plan tools.
- The obsolete durable-memory prompt and `memory-keeper` agent are removed.
- Existing task and plan files remain available.

## Tasks

- [x] Remove durable-memory creation and prompt injection from the extension.
- [x] Retain `TASKS.md` and session-plan behavior.
- [x] Remove `.ai/MEMORY.md`, `update-expertise`, and `memory-keeper`.
- [x] Remove the obsolete pending memory task and stale prompt wording.
- [x] Run targeted validation.

## Stop Rules

- Do not remove `TASKS.md` or existing session plans.
- Do not modify unrelated pre-existing working-tree changes.

## Validation Policy

Run syntax, reference, and whitespace checks only; no broad test suite is relevant to this TypeScript extension/configuration cleanup.

## Validation

- `node --check pi/.pi/agent/extensions/memory.ts` passed.
- No active durable-memory references remain in `pi/.pi/agent` or `.ai/TASKS.md`.
- Obsolete files are absent.
- Targeted `git diff --check` passed; the full-tree check reports pre-existing whitespace in `ghostty/.config/ghostty/config`.
