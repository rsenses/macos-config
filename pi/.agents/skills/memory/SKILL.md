---
name: memory
description: Manage lightweight project-local Markdown memory for coding work. Use for planning, implementing, fixing, finalizing, tracking pending tasks, or any non-trivial project task where the agent should use `.ai/MEMORY.md`, `.ai/TASKS.md`, a single session plan under `.ai/plan/`, and concise notes under `.ai/daily/`.
---

# Memory

Use project-local Markdown files as lightweight durable memory.

This skill is intentionally simple. It does not replace source code, AGENTS.md, project documentation, or user instructions.

## Storage

Use paths relative to the current working directory:

```text
.ai/MEMORY.md
.ai/TASKS.md
.ai/plan/
.ai/daily/
```

Create missing directories/files when needed.

Do not write outside the current working directory.

## Authority order

When information conflicts, follow this order:

1. current user instruction
2. AGENTS.md and project-specific rules
3. current command prompt
4. current session plan
5. `.ai/MEMORY.md`
6. `.ai/TASKS.md`
7. daily notes

Memory is context, not authority.

## Start of work

At the start of any non-trivial task:

1. Use the memory context injected by the extension.
2. If needed, read `.ai/MEMORY.md`, `.ai/TASKS.md`, and the current session plan path shown in the prompt.
3. Use memory only for relevant project context, known pitfalls, durable decisions, user preferences, pending tasks, and current plan continuity.
4. Do not let memory broaden the current task scope.

If `.ai/MEMORY.md` does not exist, create it only when useful.

Initial `.ai/MEMORY.md` template:

```md
# Project Memory

Durable project knowledge, decisions, preferences, and recurring lessons.

## Stable Preferences

- Prefer simple, direct implementations.
- Prefer framework-native and project-native solutions.
- Avoid unnecessary abstractions.
- Do not duplicate framework guarantees.

## Project Decisions

- Validation:
- Remaining:
- Notes:
```

## Session plans

Use one plan file per Pi session/task, not one plan per interaction.

The memory extension injects the current session plan path, for example:

```text
.ai/plan/YYYY-MM-DD-<session-id>-<short-slug>.md
```

The session id prevents duplicate plans in one Pi session; the slug keeps filenames understandable. If a plan already exists for the current session id, update it even if the slug is imperfect.

Rules:

- For non-trivial implementation/fix/debug/finalization work, create or update that single current session plan before changing code.
- On later turns in the same session, find the existing `.ai/plan/YYYY-MM-DD-<session-id>-*.md` file and update it instead of creating a new one.
- If the task changes materially, revise the same plan with updated status, decisions, TODOs, and remaining work.
- Do not create timestamped duplicate plans unless the user explicitly asks to archive a separate agreed plan.
- Keep the plan useful and current; it is operational, not a transcript.

Recommended plan shape:

```md
# <Task/session title>

- Status: in-progress | blocked | done
- Updated: <YYYY-MM-DD HH:mm>
- Scope: small | medium | large | unknown

## Goal

## Current Plan

## TODO

- [ ] ...

## Decisions and Constraints

## Validation

## Remaining / Next
```

## Pending tasks

Use `.ai/TASKS.md` for pending work that should survive across sessions.

Rules:

- Simple pending tasks: one-line checkbox directly in `.ai/TASKS.md`.
- Complex pending tasks: create/update a plan in `.ai/plan/` and add a checkbox in `.ai/TASKS.md` linking to it with an Obsidian-style wiki link, e.g. `[[.ai/plan/YYYY-MM-DD-topic.md]]`.
- Keep pending task entries short and actionable.
- Do not use `.ai/MEMORY.md` as a task list.
- Move completed tasks to a Done section or mark them checked when the user asks or when completion is clear.

Suggested `.ai/TASKS.md` shape:

```md
# Project Tasks

## Inbox

- [ ] Short pending task
- [ ] Complex task — see [[.ai/plan/YYYY-MM-DD-topic.md]]

## In Progress

## Done
```

## Daily notes

Append concise entries to `.ai/daily/YYYY-MM-DD.md` after meaningful work.

Keep entries short. Record outcomes, not full conversations.

Good daily entries include:

- what was implemented,
- what was fixed,
- what failed and why,
- important decisions,
- validation results,
- remaining work,
- risks for next session.

Do not store:

- full transcripts,
- long diffs,
- secrets,
- temporary logs,
- irrelevant tool output,
- speculative notes that are not useful later.

## Long-term memory updates

Update `.ai/MEMORY.md` only for durable knowledge.

Good candidates:

- repeated user preferences,
- stable project conventions,
- architecture decisions,
- recurring pitfalls,
- lessons that prevent future mistakes,
- important workflow decisions.

Bad candidates:

- one-off task details,
- pending task lists,
- temporary debugging notes,
- full command output,
- implementation minutiae,
- guesses,
- secrets or sensitive data.

When updating memory:

- prefer editing an existing relevant section,
- avoid duplicates,
- keep entries short,
- include dates only when useful,
- do not let `.ai/MEMORY.md` grow into a log.

If unsure whether something belongs in long-term memory, write it to the daily note or `.ai/TASKS.md` instead.

## End of work

At the end of meaningful work:

1. Update the current session plan status/TODOs if work changed.
2. Append a daily note.
3. Update `.ai/TASKS.md` if pending work changed.
4. Update `.ai/MEMORY.md` only if a durable lesson or decision emerged.
5. Mention files written in the final response.
