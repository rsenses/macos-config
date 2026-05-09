# Plan: project_files query robustness

- Fix `project_files` so casual glob-like queries such as `*maximo*` do not fail fd regex parsing.
- Keep behavior simple: normalize common wrapping `*` and use fd fixed-string matching for path/name discovery.
- Validate syntax with `node --check`.
