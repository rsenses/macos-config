---
description: Update project expertise files with durable lessons
argument-hint: "[lesson or focus]"
---

Use the `orchestrator` skill for this task.

Update the project's durable expertise notes based on the current conversation, recent implementation, and optional user input.

User input:
$ARGUMENTS

Goal:
Capture stable project knowledge that will help future agents work better in this codebase.

Rules:

- Store expertise under `.ai/expertise/` relative to the current working directory.
- Create `.ai/expertise/` if it does not exist.
- Do not modify application code.
- Do not store temporary task details.
- Do not store full logs, diffs, or large summaries.
- Do not duplicate AGENTS.md rules unless extra explanation is useful.
- Prefer short, durable, evidence-backed notes.
- If the lesson is project-specific, write it.
- If the lesson is generic, obvious, or already captured elsewhere, skip it.
- If unsure whether something is durable, ask before saving.
- Read existing expertise files before updating.
- Avoid contradictions and duplicate notes.
- Prefer updating an existing note over appending similar new notes.

Suggested files:

- `.ai/expertise/project.md` for high-level project model
- `.ai/expertise/architecture.md` for structure, boundaries, and conventions
- `.ai/expertise/testing.md` for testing strategy and known pitfalls
- `.ai/expertise/agent-lessons.md` for recurring AI-agent mistakes and corrections
- `.ai/expertise/decisions.md` for durable technical decisions

Each saved note should include:

- date
- short title
- lesson
- why it matters
- evidence/source from recent work, if available

Final output:

- files updated
- lessons added or changed
- anything skipped
