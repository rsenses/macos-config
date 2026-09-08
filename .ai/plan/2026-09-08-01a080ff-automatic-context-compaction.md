# Plan: automatic-context-compaction
- Status: complete
- Created: 2026-09-08
- Session ID: 01a080ff

## Goal
Replace `context-warning.ts` with a small Pi extension that automatically compacts sessions at 128k tokens using `openai-codex/gpt-5.6-luna` with `high` reasoning, then restores the original model and reasoning level safely.

## Current Step
Finished; implementation and focused behavioral tests pass.

## Spec / Contract
- Use `ctx.getContextUsage().tokens` and `agent_settled` for the safe automatic trigger.
- Reuse native `ctx.compact()`; Pi owns cut-point selection, retained tail, persistence, and context rebuild.
- Switch session-only to `openai-codex/gpt-5.6-luna` / `high` before compaction.
- Restore the original model and thinking level on both `session_compact` and `session_compact_failed`.
- Hard threshold: 128,000 tokens. Soft threshold is documented but intentionally inactive because checkpoint heuristics add complexity.
- Preserve permanent harness rules through Pi's normal system/context loading; do not copy them into the summary.
- Never mutate or replace conversation messages directly in the extension.

## Tasks
- [x] Inspect Pi 0.85.1 context, model, thinking, compaction, hook, and session APIs.
- [x] Choose safe trigger and native compaction integration.
- [x] Implement replacement extension and remove context-warning.
- [x] Add focused behavioral tests.
- [x] Run tests/type checks available locally and review race/failure behavior.

## Stop Rules
- Do not add checkpoint heuristics, emergency xhigh, custom persistence, or a parallel context manager unless required by the real APIs.
- Do not modify unrelated dirty worktree files.

## Validation Policy
Prefer focused tests that exercise observable extension behavior rather than Pi implementation details. Verify no compaction below threshold, Luna/high selection, restoration, failure safety, and no same-run repeat.

## Validation
- Pi docs and installed declarations/source inspected.
- Existing local configuration uses `openai-codex/gpt-5.6-luna` and `openai-codex/gpt-6-astra`; both have 272k context metadata in the local model store.
- `node --test pi/.pi/agent/extensions/context-compact.test.mjs` — 4 passed.
- `PI_SDK_ROOT=... node --test pi/.pi/agent/extensions/pi-subagents/integration.test.mjs` — passed.
- `tsc -p /tmp/pi-context-compact-tsconfig.json` — passed.
- `PI_OFFLINE=1 pi --list-models` — extension-compatible Pi startup/model catalogue check passed.

## Result
Implemented `context-compact.ts` with a 128k hard trigger at `agent_settled`, native Pi compaction, session-only Luna/high switching, safe restoration on success/failure/shutdown, concise working-state instructions, and same-run duplicate protection. Soft checkpoint heuristics and emergency xhigh remain intentionally out of scope.
