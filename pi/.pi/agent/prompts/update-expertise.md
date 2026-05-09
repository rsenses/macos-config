---
description: Update project memory with durable lessons
argument-hint: "[lesson or focus]"
---

Use the `orchestrator` skill for this task.
Use the `memory` skill for this task.

Update the project's durable memory based on the current conversation, recent implementation, and optional user input.

User input:
$ARGUMENTS

Goal:
Capture stable project knowledge that will help future agents work better in this codebase.

Rules:

- Store durable knowledge in `.ai/MEMORY.md` relative to the current working directory.
- Use `.ai/daily/YYYY-MM-DD.md` for task-specific outcomes, temporary context, validation results, risks, and remaining work.
- Do not create a separate `.ai/expertise/` system unless I explicitly ask for it.
- Do not modify application code.
- Do not store temporary task details in `.ai/MEMORY.md`.
- Do not store full logs, diffs, transcripts, or large summaries.
- Do not store secrets.
- Do not duplicate AGENTS.md rules unless extra explanation is useful.
- Prefer short, durable, evidence-backed notes.
- If the lesson is project-specific and likely useful later, write it.
- If the lesson is generic, obvious, temporary, or already captured elsewhere, skip it or put it in today's daily note.
- If unsure whether something is durable, ask before saving.
- Read existing `.ai/MEMORY.md` before updating.
- Avoid contradictions and duplicate notes.
- Prefer editing an existing relevant section over appending a new similar note.
- Keep `.ai/MEMORY.md` curated; it is not a changelog.

Good `.ai/MEMORY.md` candidates:

- stable project conventions
- repeated user preferences
- architecture decisions
- recurring pitfalls
- important workflow decisions
- lessons that prevent future mistakes

Bad `.ai/MEMORY.md` candidates:

- one-off implementation details
- temporary debugging notes
- command output
- guesses
- full summaries of the current task

Final output:

- files updated
- durable lessons added or changed
- daily notes added, if any
- anything skipped
