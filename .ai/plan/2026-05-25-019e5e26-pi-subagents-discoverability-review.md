# Plan: pi-subagents-discoverability-review
- Status: completed
- Created: 2026-05-25
- Session ID: 019e5e26

## Goal
Align skills/configs with the real `pi-subagents` set: `scout`, `researcher`, `worker`.

## Spec / Contract
- Keep only references to existing subagents.
- Remove stale mentions of `planner`, `delegate`, `reviewer`, `oracle`, and `context-builder`.
- Make fallback guidance explicit in the core ops prompts.

## Tasks
- [x] Review `pi/.pi/agent/extensions/pi-subagents` for ergonomics and discoverability.
- [x] Update skills/configs to match the current subagent set.

## Findings
- The `pi-subagents` extension is solid: bounded recursion, explicit allowlists, isolated child processes, and useful UI telemetry.
- The main mismatch was stale references to non-existent roles in skills/configs.
- After the edits, visible guidance now points only to the real subagents: `scout`, `researcher`, `worker`.

## Validation
- Searched `pi/.pi/agent` for old agent names and removed the stale references from skills/configs.
- No tests run; this was a prompt/config alignment pass.
