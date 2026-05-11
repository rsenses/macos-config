---
description: Save the current agreed plan to a Markdown file
---

Use the `memory` skill for this task.

Save or update the current agreed plan from this conversation in the current session plan file.

Context:
The user has already discussed and refined a plan. Your job is to persist the latest agreed plan accurately in the current session plan path injected by the memory extension, not to create a new file every time.

This command is archival and operational: the saved Markdown file should contain enough detail for a future agent or developer to implement the plan without needing to reread the full conversation.

Rules:

- Extract the latest agreed plan from the conversation.
- Preserve the user's intent, constraints, decisions, and technical details.
- Preserve concrete file paths, class names, method names, commands, components, routes, endpoints, database objects, config keys, and package names mentioned during planning.
- Preserve implementation order when it matters.
- Preserve important rejected alternatives or non-goals if they affect implementation.
- Do not invent new steps, requirements, risks, files, or verification commands.
- Do not omit details just to make the plan shorter.
- You may lightly restructure the plan for clarity, but do not weaken or generalize specific decisions.
- If a detail is uncertain, mark it as uncertain instead of removing it.
- The plan may be very small or very large; adapt the level of detail accordingly.
- Store it in the current session plan path injected by the memory extension, e.g. `.ai/plan/YYYY-MM-DD-<session-id>.md`.
- Create `.ai/plan/` if it does not exist.
- Use the current local timestamp in the file metadata.
- If the current session plan file already exists, update it instead of creating a new file.
- Do not create timestamped duplicate plans unless I explicitly ask to archive a separate plan.
- Do not edit files outside the current working directory.
- This command itself satisfies the memory plan-saving step; do not create a second duplicate plan file.
- If this plan represents pending future work, add or update a concise checkbox in `.ai/TASKS.md` linking to the plan with an Obsidian-style wiki link, e.g. `[[.ai/plan/YYYY-MM-DD-<session-id>.md]]`.

Markdown format:

# <Plan title>

- Updated: <YYYY-MM-DD HH:mm>
- Status: planned | in-progress | blocked | done
- Scope: <small | medium | large | unknown>

## Goal

<The goal of the plan. Include the user-visible or developer-visible outcome.>

## Context

<Relevant background from the conversation. Include only context that affects implementation decisions.>

## Plan

<The agreed plan. For simple plans, use a short ordered list. For larger plans, use phases or sections. Preserve concrete technical details and sequencing.>

## TODO

<A checklist derived from the agreed plan. Use checkboxes. For simple plans, use 1–3 items. For larger plans, group by phase. Do not invent tasks beyond the agreed plan.>

## Target Files and Areas

<List concrete files, directories, classes, components, routes, commands, modules, or areas likely to be modified or inspected. If exact files are unknown, say "Unknown yet" and list likely areas.>

## Decisions and Constraints

<Important decisions, constraints, non-goals, preferences, and rejected alternatives that should guide implementation.>

## Expected Changes

<Expected code, behavior, UI, API, data, configuration, or documentation changes. Be specific when the conversation was specific.>

## Risks and Open Questions

<Known risks, assumptions, or unresolved questions. Use "None identified" only if there truly are none.>

## Notes for Implementation

<Implementation guidance that must not be lost: framework conventions, existing patterns to follow, things to avoid, sequencing constraints, edge cases, and any important details from the conversation.>

After saving, reply only with:

- saved file path
- short summary
