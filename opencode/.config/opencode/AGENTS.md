# lean-ctx — Context Engineering Layer
<!-- lean-ctx-rules-v10 -->

## Mode Selection
- Editing the file? → `full` first, then `diff` for re-reads
- Context only? → `map` or `signatures`
- Large file? → `aggressive` or `entropy`
- Specific lines? → `lines:N-M`
- Unsure? → `auto`

Anti-pattern: NEVER use `full` for files you won't edit — use `map` or `signatures`.

## File Editing
Use native Edit/Write/StrReplace — unchanged. lean-ctx replaces READ only.
If Edit requires Read and Read is unavailable, use `ctx_edit(path, old_string, new_string)`.
NEVER loop on Edit failures — switch to ctx_edit immediately.

Fallback only if a lean-ctx tool is unavailable: use native equivalents.
<!-- /lean-ctx -->
