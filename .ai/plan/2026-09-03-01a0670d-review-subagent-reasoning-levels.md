# Plan: review-subagent-reasoning-levels
- Status: completed
- Created: 2026-09-03
- Session ID: 01a0670d

## Goal
Recommend per-role thinking levels for the local `pi-subagents` setup, prioritising latency and avoiding unnecessary context growth.

## Findings
- The active local extension loads each agent's explicit `thinking` value and passes it to the child Pi process with `--thinking`; the extension does not otherwise interpret the level (`pi/.pi/agent/extensions/pi-subagents/index.ts:383-400`).
- Children run with `--no-session` and `--no-skills`, so their working context is isolated from the parent. The parent receives the final textual output only; the extension truncates oversized final output using Pi's default byte/line limits (`index.ts:690-709, 1024`).
- Current agent configuration is `planner=max`, `researcher=max`, `scout=xhigh`, `worker=max`.
- `openai-codex/gpt-5.6-luna` supports `high`, `xhigh`, and `max` (normal levels are supported by default; `xhigh`/`max` are explicit in the model map). Verified locally with Pi's model helpers.
- The currently selected Codex Luna entry advertises a 272K context window. Other Luna provider entries in the local catalog advertise 1.05M, but changing provider is a separate availability/quality decision.

## Recommendation
For speed and context discipline:
- Main/orchestrator: `max`.
- `planner`: `xhigh` baseline; reserve `max` for unusually risky architecture or migration plans.
- `scout`: `high`.
- `researcher`: `high`; use `xhigh` only for conflicting or high-stakes research.
- `worker`: `high` baseline. It is bounded and can validate with tests; the main agent remains responsible for integration/review. Escalate manually to `xhigh`/`max` for security-sensitive or broad refactors.

## Caveat
Lowering a child's thinking level mainly reduces that child's reasoning tokens and latency; it is not the primary control for the parent's context. Concise worker/scout/researcher final-output instructions and bounded tasks have more direct impact on parent-context growth.

## Files inspected
- `pi/.pi/agent/settings.json`
- `pi/.pi/agent/extensions/pi-subagents/agents/{planner,researcher,scout,worker}.md`
- `pi/.pi/agent/extensions/pi-subagents/index.ts`
- `pi/.pi/agent/models-store.json`
- Installed Pi docs: `docs/models.md`, `docs/settings.md`, `docs/compaction.md`, `docs/extensions.md`

## Implementation
No agent configuration was changed in this review; the recommendation can be applied as a separate targeted edit.
