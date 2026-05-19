# Plan: tmux-sessionazer-popup-bug
- Status: done
- Created: 2026-05-19
- Session ID: 019e4055

## Goal

Fix the tmux `f` keybind so `sessionizer` stays open instead of closing instantly.

## Spec / Contract

- `prefix + f` should open a popup and keep it open while `sessionizer` runs.
- The command should work even if tmux does not inherit the same PATH as an interactive terminal.

## Tasks
- [x] Inspect tmux binding and sessionizer script.
- [x] Reproduce the popup PATH mismatch with a debug bind.
- [x] Switch the popup binding to the absolute `sessionizer` path.

## Validation
- [ ] Reload tmux and press `prefix + f`.
- [ ] Confirm the popup remains open and shows the picker.
- [ ] Confirm `prefix + F` writes a debug file and no longer depends on `sessionizer` being on PATH.
