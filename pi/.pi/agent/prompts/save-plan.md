---
description: Save the current agreed plan to a Markdown file
---

Save the current agreed plan from this conversation to a Markdown file.

Context:
The user has already discussed and refined a plan. Your job is to persist the latest agreed plan, not to create a new one.

Rules:

- Extract the latest agreed plan from the conversation.
- Preserve the user's intent, constraints, and decisions.
- Do not invent new steps, requirements, risks, or verification commands.
- You may lightly restructure the plan for clarity.
- The plan may be very small or very large; adapt the level of detail accordingly.
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
- Scope: <small | medium | large | unknown>

## Goal

<Brief goal of the plan>

## Context

<Relevant background from the conversation, only if useful>

## Plan

<The agreed plan. Use a short checklist for simple plans and sections/phases for larger plans.>

## Decisions and Constraints

<Important decisions, constraints, non-goals, or preferences agreed during planning>

## Expected Changes

<Likely areas/files/components affected, if known. Keep generic if unknown.>

## Risks and Open Questions

<Known risks, assumptions, or unresolved questions. Use "None identified" if none.>

## Notes for Implementation

<Useful guidance for whoever executes the plan. Keep concise.>

After saving, reply only with:

- saved file path
- short summary
