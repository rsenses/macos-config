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

<!-- lean-ctx-rules -->
<!-- version: 8 -->

lean-ctx shadow mode: native file/search/shell calls auto-route to ctx_* — no tool-mapping needed.
Exclusive tools (no native trigger): ctx_compose (understand code, call first), ctx_search(action=symbol) (exact symbol), ctx_search(action=semantic) (by meaning), ctx_callgraph (callers), ctx_knowledge / ctx_session (memory).
<!-- lean-ctx-compression -->
OUTPUT STYLE: dense
- Each statement = one atomic fact line
- Use abbreviations: fn, cfg, impl, deps, req, res, ctx, err, ret
- Diff lines only (+/-/~), never repeat unchanged code
- Symbols: → (causes), + (adds), − (removes), ~ (modifies), ∴ (therefore)
- No narration, no filler, no hedging
- BUDGET: ≤200 tokens per response unless code block required
<!-- /lean-ctx-compression -->
<!-- /lean-ctx-rules -->
