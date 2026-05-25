# Plan: compare-ast-grep-extension
- Status: done
- Created: 2026-05-20
- Session ID: 019e4502

## Spec / Contract
- [x] Identify current ast-grep availability/configuration in this Pi harness.
- [x] Fetch and inspect https://github.com/Elsin/pi-ast_grep.
- [x] Compare capabilities, behavior, and installation implications.

## Findings
- Current harness exposes an `ast_grep` tool with `pattern`, `rule`, and `inspect` modes, rich guidance, globs/context/limit, and no replace/apply mode.
- Project Pi settings do not include a local `pi-ast-grep` package/extension; the current tool appears harness-provided rather than installed from this repo.
- `sg` CLI is available at `/opt/homebrew/bin/sg`, version `0.42.3`.
- Elsin/pi-ast_grep defines two Pi tools: `ast_grep_search` and `ast_grep_replace`, wrapping `sg run` with compact JSON output.

## Implementation
- Created `pi/.pi/agent/extensions/ast-grep.ts` as a replacement `ast_grep` tool.
- Kept one-tool UX with `mode: pattern | rule | inspect | replace`.
- Added AST rewrite support with dry-run by default and `apply: true` for `sg --update-all`.
- Rule mode wraps the provided YAML body in a temporary full ast-grep rule file.

## Validation
- Inspected `pi/.pi/agent/settings.json`, `pi/.pi/agent/extensions/`, the fetched repo files, and verified `sg --version`.
- Loaded a temporary `ast_grep_test` variant with `pi --no-extensions -e ...`.
- Smoke-tested `pattern`, `rule`, `inspect`, and dry-run `replace` modes through Pi print mode.
- Direct `ast_grep` load still conflicts until the currently installed ast-grep extension/package is removed.
