# Plan: strengthen-plan-persistence
- Status: complete
- Created: 2026-09-08
- Session ID: 01a08146

## Goal
Make `/plan` persist the complete, task-specific implementation plan—not a shortened summary—so a later reviewer or executor can rely on the file as the canonical source of truth.

## Known
- The target command is `pi/.pi/agent/prompts/plan.md`.
- The current prompt asks for a “compact canonical contract” and a brief final delta, but does not explicitly require the displayed detail to be persisted or read back.
- `create_session_plan` only creates a template; the model must populate the returned path.
- Preserve unrelated pre-existing worktree changes.

## Evidence
- `pi/.pi/agent/prompts/plan.md`: current rules 3–6 permit a persisted plan but do not define parity between chat output and the plan file.
- `pi/.pi/agent/extensions/memory.ts`: `create_session_plan` returns a path and `get_current_plan` previews an existing file; the command prompt therefore needs to direct the model to write and verify the file explicitly.
- No root `CHANGELOG.md` exists.

## Acceptance
- `plan.md` makes the persisted session-plan file the canonical deliverable.
- It explicitly requires all material planning detail to be written to the file before the final response, forbids a detailed chat-only plan or minimal file, and requires read-back verification.
- It preserves the existing contract, planning-only boundary, selective delegation, and concise final reporting.

## Tasks
1. Update `pi/.pi/agent/prompts/plan.md` with explicit persistence/parity/read-back rules and a task-detail checklist.
2. Review the resulting prompt for contradictory instructions or accidental implementation-file scope.
3. Validate the diff and markdown content with targeted local inspection.

## Checks
- Read the edited prompt end to end.
- Run `git diff --check`.
- Inspect `git diff -- pi/.pi/agent/prompts/plan.md` and confirm only the requested prompt changed.

## Stop Rules
- Do not modify runtime extensions or implementation files.
- Do not alter unrelated pre-existing changes.
- Stop and report if the target prompt’s workflow contract conflicts with the persistence requirement.

## Validation
- [x] Prompt edited.
- [x] Prompt reread and consistency reviewed.
- [x] `git diff --check` passes.
