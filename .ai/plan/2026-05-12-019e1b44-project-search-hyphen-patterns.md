# Session Plan: project_search hyphen-safe queries

## Goal
Fix `pi/.pi/agent/extensions/project-context.ts` so `project_search` can search patterns that begin with `-` (for example `->mount(`) without `rg` treating them as flags.

## Contract
- `project_search` must pass the user query to `rg` in a way that cannot be parsed as an option.
- Existing behavior for normal queries must remain unchanged.
- Keep the fix minimal and local.

## TODO
- [x] Update `project_search` argument construction to handle leading-`-` / regex-invalid queries safely.
- [x] Validate the resulting command shape with a quick command check.
- [x] Record the outcome in project memory.
