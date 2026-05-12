# Agent skills integration

- Status: in-progress
- Updated: 2026-05-12
- Scope: medium

## Goal

Plan what to add or modify under `pi/.agents/skills` using `addyosmani/agent-skills` plus the user's existing `.ai/guidelines` conventions.

## Current Plan

1. Inspect current dotfiles skills.
2. Inspect cloned agent-skills catalog and relevant skill content.
3. Inspect project guidelines from cobra worktree.
4. Propose a curated skill set and adaptations before making file changes.

## TODO

- [x] Read current `memory`, `orchestrator`, and `ship` skills.
- [x] Read cobra `.ai/guidelines` files.
- [x] Summarize agent-skills catalog.
- [x] Agree on exact skill set and naming.
- [x] Implement selected skills/adaptations in `pi/.agents/skills`.
- [x] Review and align existing skills (`memory`, `orchestrator`, `ship`).
- [x] Review and align prompt templates under `pi/.pi/agent/prompts`.
- [x] Neutralize Node/TypeScript-specific command defaults.
- [x] Validate skill frontmatter/discovery shape.
- [ ] Optional second-pass review after using the skills in real tasks.

## Decisions and Constraints

- Do not import strict TDD wholesale; adapt to pragmatic testing.
- Preserve existing `memory`, `orchestrator`, and `ship` as first-class skills.
- Guidelines are mutable; skills should absorb reusable workflow rules rather than duplicate project-specific details blindly.

## Validation

Validated all `pi/.agents/skills/*/SKILL.md` files have `name` and `description` frontmatter matching directory names. Searched skills/prompts for stack-specific command leftovers (`npm`, `npx`, `composer fix/test`, strict PHPStan status wording, TDD-lite, autonomous/proactive wording); no problematic command defaults remain.

## Remaining / Next

Use the curated skills in real tasks and refine activation wording if any skill triggers too aggressively or not enough.
