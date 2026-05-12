---
description: Refine recently changed Laravel/PHP code for simplicity
---

Use the `orchestrator` skill for this task.
Use the `memory` skill for this task.
Use the `code-simplification` skill for this task.
Use project-specific AGENTS.md rules for Laravel conventions; do not duplicate or override them here.

# Laravel Code Simplifier

Refine recently modified PHP/Laravel code for clarity, consistency, and maintainability while preserving exact behavior.

This command is not a broad architecture rewrite. It should make the current diff easier to understand and safer to review.

## Rules

- Only inspect and refine code touched in the current branch/session unless explicitly asked for a broader pass.
- Preserve behavior exactly.
- Do not introduce unrelated refactors.
- Do not create new abstractions unless they clearly reduce complexity now and match project conventions.
- Prefer framework-native and project-native patterns from AGENTS.md and existing code.
- Do not duplicate guarantees already provided by middleware, validation, policies/gates, route model binding, types, or existing control flow.
- Prefer readable explicit code over dense clever code.
- Avoid nested ternaries; prefer clear conditionals or `match` when appropriate.
- Remove comments only when they are obviously redundant; preserve comments that explain intent, constraints, or non-obvious behavior.
- Do not run full test suites or formatters unless explicitly requested.
- Run narrow static analysis or targeted checks only when relevant and cheap.
- Do not commit.

## Process

1. Inspect the current git diff and recently modified files.
2. Identify simplifications with clear payoff.
3. Apply only focused refinements.
4. Re-read the changed diff to confirm behavior was preserved.
5. Run targeted project checks if relevant.
6. Append a concise daily note only if meaningful refinements were made.

## Stop conditions

Stop and ask before changing files if:

- the simplification would alter behavior,
- project conventions conflict,
- the diff contains multiple unrelated concerns,
- the best improvement is architectural and larger than a focused cleanup,
- a new abstraction or dependency seems necessary.

## Final output

- files changed
- simplifications made
- behavior-preservation notes
- targeted checks run, if any
- risks or follow-ups
- memory/daily entry status
