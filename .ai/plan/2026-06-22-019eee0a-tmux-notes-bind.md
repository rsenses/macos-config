# Plan: tmux-notes-bind
- Status: done
- Created: 2026-06-22
- Session ID: 019eee0a

## Goal
Fix the tmux `N` binding that opens a `notes` window and immediately closes.

## Findings
- `tmux/.config/tmux/tmux.conf` binds `N` to `new-window ... "notes"`.
- `notes` is a zsh function defined in `zsh/.config/zsh/.zshfunctions` and sourced from `.zshrc`.
- tmux shell commands are not run as an interactive zsh that sources `.zshrc`, so the function is unavailable and the new window exits immediately.

## Expected Change
- Make the tmux binding launch an interactive zsh command so `.zshrc` loads the `notes` function before invoking it.

## Validation Policy
- Validate by checking tmux config syntax with `tmux -f tmux/.config/tmux/tmux.conf start-server` or equivalent if tmux is available.

## Result
- The tmux `N` binding now runs `zsh -ic 'notes'`, ensuring `.zshrc` is sourced and the `notes` function is available.
- Validation passed with `tmux -f tmux/.config/tmux/tmux.conf start-server` (exit 0, no errors).
- A backup was created at `tmux/.config/tmux/tmux.conf.bak-20260622083647`.
