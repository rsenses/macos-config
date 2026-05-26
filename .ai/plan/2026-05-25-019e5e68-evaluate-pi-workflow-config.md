# Plan: evaluate-pi-workflow-config
- Status: in-progress
- Created: 2026-05-25
- Session ID: 019e5e68

## Goal
Tighten the plan/run templates with smallcode-style loop control while keeping token overhead low.

## Spec / Contract
- Keep changes surgical and text-only.
- Improve plan template clarity (`Current Step`, `Stop Rules`, `Validation Policy`).
- Add a small retry/loop-control rule to `APPEND_SYSTEM.md` and `run-plan.md`.
- Add memory-oriented inspection tools without bloating the harness.

## Tasks
- [x] Update the session plan template in `memory.ts`.
- [x] Add loop-control language to `APPEND_SYSTEM.md` and `run-plan.md`.
- [x] Add `get_current_plan` and `summarize_worktree` tools to `memory.ts`.
- [x] Review for token bloat and keep text minimal.

## Validation
- Reviewed the changed prompts and memory tools for brevity and consistency.
