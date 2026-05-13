# Memory auto-persistence hardening

- Updated: 2026-05-13
- Status: in-progress
- Scope: medium

## Goal

Review why `.ai/MEMORY.md`, `.ai/TASKS.md`, and daily notes were not being persisted consistently, then harden the prompt-driven flow with the smallest practical change.

## Spec / Contract

- Objective: determine whether memory persistence is only manual/contextual or if there is an automatic write path missing.
- Expected behavior: memory, tasks, and daily notes should persist the right level of information without requiring fragile manual steps for every meaningful session.
- Success criteria: clear understanding of why entries are missing and a practical path to improve coverage.
- Out of scope: changing unrelated agent workflows.
- Open questions: should persistence happen via automatic hooks, model prompts, or a small helper command?

## Current Plan

- Inspect the memory extension hooks and current prompt-driven persistence flow.
- Verify where memory/tasks/daily are supposed to be updated versus merely injected as context.
- Identify whether a small automatic write path or prompt tweak would solve the gaps.
- Record findings and next steps.

## TODO

- [x] Inspect `memory.ts`, `update-expertise.md`, `save-plan.md`, and current `.ai/` state.
- [x] Compare expected persistence against actual behavior.
- [x] Decide to keep the flow prompt-driven but make file-write language explicit.
- [x] Harden the relevant prompts/skill text to say "write the file" rather than only "update".
- [x] Fix the extension parse error caused by an unescaped backtick in the injected prompt text.

## Decisions and Constraints

- Memory extension currently injects context; it does not write durable memory or tasks by itself.
- Daily files are created automatically, but content persistence still depends on the agent/prompt flow.
- Prompt wording should say "write the file" explicitly; advisory phrasing alone is easier for the model to narrate than to execute.
- Prefer the smallest change that improves persistence without adding noisy or low-value logs.

## Validation

- Reread `memory.ts`, `finalize.md`, `memory/SKILL.md`, and `.ai/MEMORY.md` after the wording change.
- `git diff --check` passed after the edits.

## Remaining / Next

- Observe future tasks to see whether the stronger wording improves actual file writes.
- If persistence still slips, revisit a hook-based fallback; keep it small and scoped.
- Confirm the extension now loads cleanly after the backtick escape fix.

