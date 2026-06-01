---
name: ast-grep
description: Guide for using the ast_grep Pi tool for structural code search, AST inspection, YAML rule queries, and AST-aware rewrites. Use when searching code by syntax/structure, debugging ast-grep patterns, or safely replacing code with dry-run/apply workflow.
---

# ast-grep Structural Search and Rewrite

Use the `ast_grep` tool for ast-grep operations. It supports four modes:

- `pattern` — quick AST pattern search.
- `rule` — YAML rule body search for relational/composite logic.
- `inspect` — AST/CST/pattern dump to debug node kinds and patterns.
- `replace` — AST-aware rewrite; **dry-run by default**, only modifies files with `apply: true`.

## Default Workflow

1. Start with `pattern` for simple structure searches.
2. Use `inspect` when the pattern/rule does not match or node kinds are unclear.
3. Escalate to `rule` only for relational, negative, or composite logic.
4. Use `replace` only after a search confirms the target shape; run dry-run first, then `apply: true` only when the preview is correct.

## Pattern Search

Use for straightforward syntax-aware searches:

```json
{
  "mode": "pattern",
  "pattern": "console.log($MSG)",
  "lang": "typescript",
  "paths": ["src"]
}
```

Metavariables:

- `$VAR` captures one named AST node.
- `$$VAR` captures one unnamed node/token.
- `$$$VAR` captures zero or more nodes.
- `$_VAR` is a non-capturing wildcard.

Prefer `pattern` when the code shape is clear. Do not jump to complex YAML rules unless needed.

## Rule Search

Use `rule` mode for:

- `has` / `inside` relationships.
- `not` negation.
- `any` alternatives.
- `all` combinations and ordered metavariable binding.

Pass only the YAML body that belongs under `rule:`; the tool wraps it in a full ast-grep rule file.

```json
{
  "mode": "rule",
  "lang": "typescript",
  "rule": "all:\n  - kind: function_declaration\n  - has:\n      pattern: await $EXPR\n      stopBy: end\n  - not:\n      has:\n        pattern: try { $$$BODY } catch ($ERR) { $$$HANDLER }\n        stopBy: end"
}
```

Important: when using `has` or `inside`, include `stopBy: end` unless you deliberately want shallow matching.

## Inspect Mode

Use `inspect` to discover AST node kinds and debug why a query fails:

```json
{
  "mode": "inspect",
  "pattern": "async function foo() { await bar(); }",
  "lang": "javascript",
  "inspect_format": "ast"
}
```

Available formats: `ast`, `cst`, `pattern`, `sexp`.

## Replace Mode

Use `replace` for structural rewrites. It is safe by default because it previews changes without editing files.

Dry-run:

```json
{
  "mode": "replace",
  "pattern": "console.log($MSG)",
  "rewrite": "logger.info($MSG)",
  "lang": "typescript",
  "paths": ["src"]
}
```

Apply only after reviewing the dry-run result:

```json
{
  "mode": "replace",
  "pattern": "console.log($MSG)",
  "rewrite": "logger.info($MSG)",
  "lang": "typescript",
  "paths": ["src"],
  "apply": true
}
```

Before applying broad rewrites:

- Narrow `paths` and `globs`.
- Check representative matches.
- Prefer a dry-run first.
- Avoid `apply: true` if the preview includes unrelated matches.

## Common Pitfalls

- Wrong `lang`: set it explicitly.
- Wrong node kind: use `inspect`.
- Missing `stopBy: end` in `has`/`inside` rules.
- Over-specific patterns: generalize with metavariables.
- Using text grep for structural tasks: prefer `ast_grep` when syntax matters.
- Applying rewrites too early: dry-run first.
