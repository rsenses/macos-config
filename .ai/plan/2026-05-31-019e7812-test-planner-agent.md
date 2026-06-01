# Implementation Plan — Update Pi from Terminal

## Goal
Provide a simple, repeatable procedure to update the Pi coding agent harness from the terminal.

## Tasks

1. **Check current version**
   - Command: `pi --version`
   - Current: **0.78.0** (from settings.json `lastChangelogVersion`)

2. **Check for available updates**
   - Command: `npm outdated -g @earendil-works/pi-coding-agent`
   - Shows current vs. latest version side by side

3. **Update Pi**
   - Command: `npm install -g @earendil-works/pi-coding-agent@latest`
   - No `sudo` needed (mise-managed prefix, not system global)

4. **Verify update**
   - Command: `pi --version` — confirm new version
   - Run a quick `pi --help` to smoke test

5. **Rollback if needed**
   - Command: `npm install -g @earendil-works/pi-coding-agent@0.78.0`
   - Record the version before updating so you can roll back easily

## Files to Modify
- None — this is all interactive terminal commands.

## New Files
- None required.
- Optional: add a shell function to dotfiles for convenience (e.g., `pi-update` that checks version, updates, and verifies).

## Dependencies
- Task 3 depends on Task 2 (only update if there's a new version)
- Task 5 only applies if Task 4 fails

## Risks
- **Mise Node version scoping**: global packages are per-Node-version. If you switch mise Node versions, you'll need to reinstall Pi for each version.
- **Major version bumps**: `@latest` will pull the newest major. Use `@^0.78` for patch-only updates.
- **Config compatibility**: Pi config (`pi/.pi/agent/`) is user-managed and untouched by updates. But a major version bump may introduce new required settings or deprecate old ones.
