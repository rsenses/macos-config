# Memory tasks and session plan policy

- Status: done
- Updated: 2026-05-09
- Scope: medium

## Goal

Add pending-task storage and stop creating many plan files during one Pi session.

## Current Plan

- Extend the memory extension to create/inject `.ai/TASKS.md`.
- Inject a stable current session plan path based on date and Pi session id.
- Update memory policy so non-trivial work updates that single session plan instead of creating timestamped plans per interaction.
- Update the memory skill with rules for session plans and pending tasks.
- Update `/save-plan` to update the current session plan and optionally link pending work in `.ai/TASKS.md`.

## TODO

- [x] Update memory extension.
- [x] Update memory skill.
- [x] Update save-plan prompt.
- [x] Validate extension syntax.

## Decisions and Constraints

- Pending tasks live in `.ai/TASKS.md`.
- Simple tasks are one-line checkboxes.
- Complex tasks link to a plan in `.ai/plan/`.
- `.ai/MEMORY.md` remains curated durable context, not a task list.
- Plans are operational and per session/task, not per message.

## Validation

- `node --check pi/.pi/agent/extensions/memory.ts` passed.

## Remaining / Next

- Test in a new Pi session to confirm the injected current session plan path appears and is followed.
