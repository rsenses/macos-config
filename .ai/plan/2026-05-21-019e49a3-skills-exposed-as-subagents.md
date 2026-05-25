# Plan: skills-exposed-as-subagents
- Status: investigated
- Created: 2026-05-21
- Session ID: 019e49a3

## Spec / Contract
- Diagnose why `pi-subagents` lists skill files (`SKILL.md`) as executable agents.
- Avoid changing installed packages unless explicitly requested.

## Findings
- `pi-subagents/src/agents/agents.ts` discovers agents by recursively loading every `.md` under `~/.agents` and project `.agents`, excluding only `.chain.md`.
- `~/.agents/skills/*/SKILL.md` has `name` + `description` frontmatter, so it satisfies agent parsing and gets registered as an agent.
- This conflicts with Pi skill docs, where `~/.agents/skills/**/SKILL.md` is a skill discovery location, not an agent location.

## Validation
- Confirmed `subagent list` exposes `architect/dev/ops` from skill files.
- Read Pi skills documentation and `pi-subagents` discovery code.
