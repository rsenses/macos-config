# Plan: herdr-workspace-sessionizer
- Status: done
- Created: 2026-06-25
- Session ID: 019efdff

## Goal
Add a Herdr equivalent of `bin/.local/bin/sessionizer` that picks a project/worktree, reuses an existing Herdr workspace when possible, otherwise creates one, then focuses/attaches to Herdr.

## Spec / Contract
- Reuse the existing tmux sessionizer project/worktree selection behavior where practical.
- Derive a stable label from the selected directory using the same naming rules as the tmux session name.
- Check `herdr workspace list` before creating.
- Prefer matching an existing workspace by `cwd`; fall back to matching by label.
- Create with `herdr workspace create --cwd PATH --label TEXT --no-focus` when missing.
- Focus the workspace with `herdr workspace focus ID` and attach with `herdr`.

## Validation Policy
- Shell syntax check for the new script.
- [x] Shell syntax checked with bash -n bin/.local/bin/herdr-sessionizer
- Do not require a running Herdr server for validation in this environment.

## Result
- Added bin/.local/bin/herdr-sessionizer.
- No CHANGELOG.md exists at repo root, so no changelog entry was added.
- Updated script to start a headless Herdr server with `herdr server` when `herdr workspace list` fails because no server/socket exists, then retry workspace listing before create/focus.
- Simplified current script per user request: after selecting project/worktree it now only runs `herdr workspace create --cwd DIR --label LABEL --focus`; existing workspace reuse/listing will be refined later.

## Stop Rules
- If Herdr JSON schema differs from assumed `id`, `cwd`, and `label` fields, stop and ask for live command output.
