---
description: Save the current agreed plan to a Markdown file
---

Use the `context-builder` subagent for this task.

Save the current plan from this conversation to a Markdown file.

Context:

The user has already discussed and refined a plan with you. Your job is not to create a new plan, but to persist the current agreed plan.

Rules:

- Extract the latest agreed plan from the conversation.
- Do not invent new steps.
- Do not significantly rewrite the plan except to make it clear and structured.
- Store it in `.ai/plan/` relative to the current working directory.
- Create `.ai/plan/` if it does not exist.
- Use the current local timestamp.
- Filename format: `YYYY-MM-DD-HHmm-short-slug.md`.
- Do not overwrite existing files.
- Do not edit files outside the current working directory.

Markdown format:

# <Plan title>

- Timestamp: <YYYY-MM-DD HH:mm>
- Status: planned

## Goal

<Brief goal of the plan>

## Approved Plan

<The current agreed plan>

## Constraints

<Important constraints decided during planning>

## Risks

<Known risks or open concerns>

## Verification

<Tests, refactor commands, review steps, or checks to run>

After saving, reply only with:

- saved file path
- short summary
