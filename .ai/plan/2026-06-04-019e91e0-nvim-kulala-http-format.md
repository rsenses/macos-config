# Plan: nvim-kulala-http-format
- Status: done
- Created: 2026-06-04
- Session ID: 019e91e0

## Goal
Prevent Neovim autoformat/indent from breaking Kulala `.http` variable syntax by inserting spaces around `=`.

## Findings
- Formatting setup lives in `nvim/.config/nvim/lua/custom/pack.lua`.
- `conform.nvim` runs on save with LSP fallback for most filetypes; there is no explicit `.http` formatter configured.
- No HTTP LSP is configured in the repo, but disabling format-on-save for `http` is the safest targeted guard.
- Treesitter indent is globally enabled, so HTTP buffers can also be affected by parser-based indentation.

## Changes
- In `pack.lua`, `format_on_save` now returns nil for `filetype == 'http'`.
- In `pack.lua`, Treesitter indent disables `http` via `disable = { 'http' }`.

## Validation
- `luac -p nvim/.config/nvim/lua/custom/pack.lua` passed.

## Follow-up
- If spacing around `=` still appears while typing, add `nvim/.config/nvim/after/ftplugin/http.lua` to clear buffer-local `formatexpr`/`indentexpr` for HTTP files.
