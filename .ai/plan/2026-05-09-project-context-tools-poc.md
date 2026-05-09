# Plan: project context tools POC

- Add a small Pi extension with two repo retrieval tools:
  - `project_files`: find likely relevant file paths with tight limits.
  - `project_search`: search content with grouped, capped results.
- Keep implementation simple and local: shell out to `fd`/`rg`, with conservative excludes and token-friendly output.
- Avoid indexing, embeddings, caches, or framework-specific parsing in this POC.
- Append a short daily note after implementation.
