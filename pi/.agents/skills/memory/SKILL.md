---
name: memory
description: Manage lightweight project-local Markdown memory for coding work. Use for planning, implementing, fixing, finalizing, or any non-trivial project task where the agent should read `.ai/MEMORY.md`, save dated plans under `.ai/plan/`, and append concise development notes under `.ai/daily/`. This skill provides a minimal file-based alternative to memory extensions.
---

# Memory

Use project-local Markdown files as lightweight durable memory.

This skill is intentionally simple. It does not replace source code, AGENTS.md, project documentation, or user instructions.

## Storage

Use paths relative to the current working directory:

```text
.ai/MEMORY.md
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
4. saved plan
5. `.ai/MEMORY.md`
6. daily notes

Memory is context, not authority.

## Start of work

At the start of any non-trivial task:

1. Check whether `.ai/MEMORY.md` exists.
2. If it exists, read it before planning or implementation.
3. Use it only for relevant project context, known pitfalls, durable decisions, and user preferences.
4. Do not let memory broaden the current task scope.

If `.ai/MEMORY.md` does not exist, create it only when useful.

Initial template:

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

If unsure whether something belongs in long-term memory, write it to the daily note instead.

## Scratchpad behavior

This POC does not use a separate scratchpad file.

Deferred work should go in the daily note under `Remaining`.

Only promote deferred work to `.ai/MEMORY.md` if it becomes a durable project lesson or recurring concern.

## End of work

At the end of meaningful work:

1. Append a daily note.
2. Update `.ai/MEMORY.md` only if a durable lesson or decision emerged.
3. Mention files written in the final response.
