# Plan: context-growth-and-looping
- Status: in-progress
- Created: 2026-05-28
- Session ID: 019e6da9

## Goal
Reduce prompt/context bloat in pi and stop repeated restatements of already-documented inventories (routes, components, files) during plan-driven work.

## Current Step
Audit and tighten always-on memory injection and add explicit anti-duplication guidance to the planning/system prompts.

## Spec / Contract
- Context should stay compact across iterative frontend/CSS/JS work.
- The agent should prefer deltas and references over re-listing items already captured in the plan or memory.
- Existing workflow should stay intact; this is a prompt/context tuning change, not a behavior rewrite.

## Tasks
- [ ] Task 1: Reduce always-on memory payload in `pi/.pi/agent/extensions/memory.ts`.
  - Scope: cap daily log previews and add compact context guidance.
  - Acceptance: daily context no longer injects large multi-hundred-line previews every turn.
- [ ] Task 2: Strengthen anti-repetition rules in the prompt/system files.
  - Scope: update plan/run/finalize prompts and `APPEND_SYSTEM.md`.
  - Acceptance: instructions clearly tell the model to cite existing inventories instead of restating them.
- [ ] Task 3: Sanity-check the updated prompt text for consistency and obvious regressions.
  - Scope: review the final diff only; no broad test suite required.
  - Acceptance: changes are internally consistent and easy to read.

## Stop Rules
- If a change would remove needed durable memory entirely, stop and keep a bounded preview instead.
- If prompt wording becomes ambiguous or contradictory, simplify it before proceeding.

## Validation Policy
- Use targeted inspection only.
- No full test suite is needed for this config-only change unless a syntax issue appears.

## Validation
- Pending.
