---
description: Create a GitHub issue from the current plan using gh CLI
argument-hint: "<type: bug|feature> [optional title]"
---

Create a GitHub issue using the GitHub CLI (`gh`) based on the current agreed plan or the latest saved plan.

Input:
$ARGUMENTS

Rules:

- Determine the issue type:
  - If explicitly provided in arguments, use it.
  - Otherwise infer from context (default to "feature").
- Allowed types: "feature", "bug".
- Use the latest agreed plan from the conversation or the most recent `.ai/plan/*.md`.
- Do not invent requirements.
- Keep the issue concise, clear, and actionable.
- Do not include unnecessary implementation detail.
- Do not modify any files.

Issue format:

Title:

- If a title is provided in arguments, use it.
- Otherwise generate a concise title.

Body:

## Goal

<Brief goal>

## Context

<Relevant context>

## Plan

<Short version of the plan>

## Acceptance Criteria

- [ ] ...

## Notes / Constraints

<Only if relevant>

Labels:

- Always include either `bug` or `feature`.

Execution:

- Use `gh issue create`
- Use `--title`
- Use `--body`
- Use `--label`

Example command:

gh issue create \
 --title "<title>" \
 --body "<body>" \
 --label "<type>"

If `gh` is not available or fails:

- Output the title, body, and labels instead of executing.

Final output:

- issue title
- labels
- confirmation or fallback output
