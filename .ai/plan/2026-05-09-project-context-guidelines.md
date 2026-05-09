# Plan: project context tool guidelines

- Update `project-context` tool prompt guidelines to prefer compact retrieval tools over raw `rg`/`fd`/full reads for discovery.
- Add general guidance to verify actual behavior by checking both definitions and call sites/triggers/conditions.
- Keep tools generic and avoid framework-specific logic.
- Validate syntax with `node --check`.
