# Project-context simplification

- Updated: 2026-05-12 13:40  
- Status: in-progress  
- Scope: medium

## Goal

Simplify `pi/.pi/agent/extensions/project-context.ts` without changing behavior.

## Spec / Contract

- Objective: reduce reader effort in the project search/read-window extension.
- Expected behavior: preserve current tool behavior, especially literal `$` searches and explicit regex support.
- Success criteria: clearer control flow, smaller main functions, no behavior regressions.
- Out of scope: changing tool features or semantics.
- Open questions: none.

## Current Plan

- Inspect the current extension for simplification opportunities.
- Extract only the helpers that reduce repetition or nesting.
- Keep the search/read behavior exactly as-is.
- Validate the edited file as far as the environment allows.

## TODO

- [x] Inspect the extension and identify simplification seams.
- [x] Apply a small, behavior-preserving refactor.
- [ ] Validate the refactor.

## Decisions and Constraints

- Prefer clarity over compactness.
- Avoid drive-by changes outside `project-context.ts`.
- Keep the literal-by-default `$` search behavior.

## Validation

- `git diff --check` passed.
- TypeScript CLI validation is blocked in this environment because local module/type dependencies are unavailable.

## Remaining / Next

- Validate the refactor and decide if any further simplification is still worth it.

