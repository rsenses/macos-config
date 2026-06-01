# Implementation Plan

## Goal

Provide a clear, repeatable procedure for updating the Pi coding agent (`@earendil-works/pi-coding-agent`) from the terminal, including version checks, update, verification, and rollback.

## Context

- **Package**: `@earendil-works/pi-coding-agent`
- **Current version**: `0.78.0`
- **Install method**: npm global install (`npm install -g @earendil-works/pi-coding-agent`)
- **Node manager**: mise (v24.13.0)
- **Global path**: `~/.local/share/mise/installs/node/24.13.0/lib/node_modules/@earendil-works/pi-coding-agent`
- **Config dir**: `~/.pi/agent/` (dotfiles symlinked at `dotfiles/pi/.pi/agent/`)
- **Binary name**: `pi`
- **Node engine requirement**: `>=22.19.0`

## Tasks

### 1. Check the current installed version

- **Command**: `pi --version` or `npm list -g @earendil-works/pi-coding-agent --depth=0`
- **Expected output**: Version string like `0.78.0`
- **Alternative**: Read `package.json` directly from the global install path:
  ```
  cat $(npm root -g)/@earendil-works/pi-coding-agent/package.json | grep '"version"'
  ```

### 2. Check for available updates

- **Command**: `npm outdated -g @earendil-works/pi-coding-agent`
- **What it shows**: Current version, wanted version, and latest version available on the registry
- **Alternative (registry-only)**: `npm view @earendil-works/pi-coding-agent version` — shows the latest published version

### 3. Update Pi to the latest version

- **Command**: `npm update -g @earendil-works/pi-coding-agent`
- **If `npm update` doesn't pick up a major version bump**, use explicit install:
  ```
  npm install -g @earendil-works/pi-coding-agent@latest
  ```
- **Note**: Since mise manages Node, ensure the correct Node version is active (`mise use node` or `mise exec node -- ...`) before running npm commands. The global install is scoped to the active Node version under mise.

### 4. Verify the update worked

- **Command**: `pi --version`
- **Confirm** the version matches the expected new version from step 2
- **Quick smoke test**: Launch `pi` in a test directory and verify it starts without errors

### 5. Roll back if something breaks

- **Find previously installed version**: Check your shell history or the version noted in step 1
- **Rollback command**:
  ```
  npm install -g @earendil-works/pi-coding-agent@<previous-version>
  ```
  For example, to roll back to `0.78.0`:
  ```
  npm install -g @earendil-works/pi-coding-agent@0.78.0
  ```
- **Verify rollback**: `pi --version` should show the target version

### 6. (Optional) Create a convenience shell alias or script

Add to `~/.zshrc` or a dotfiles-managed shell functions file (e.g., `zsh/.config/zsh/.zshfunctions`):

```bash
pi-update() {
  echo "Current version: $(pi --version 2>/dev/null || echo 'unknown')"
  echo "Checking for updates..."
  npm outdated -g @earendil-works/pi-coding-agent 2>/dev/null
  echo ""
  echo "Updating..."
  npm install -g @earendil-works/pi-coding-agent@latest
  echo ""
  echo "New version: $(pi --version)"
}
```

## Files to Modify

- None required for the basic procedure (all commands are run interactively)

## New Files

- None required. Optionally, a shell function can be added to `zsh/.config/zsh/.zshfunctions` for convenience.

## Dependencies

- Task 1 (check version) should be done before Task 3 (update) so you know the rollback target
- Task 2 (check updates) should be done before Task 3 to know if an update is available
- Task 4 (verify) must follow Task 3
- Task 5 (rollback) only needed if Task 4 fails

## Risks

1. **Mise Node version mismatch**: If `mise` switches to a different Node version, the global npm packages are scoped to that version's prefix. Always ensure the intended Node version is active (`mise current node`) before updating.
2. **Major version bumps**: `npm update -g` respects semver ranges and may not install major version bumps. Use `npm install -g @earendil-works/pi-coding-agent@latest` to force the absolute latest.
3. **Config compatibility**: After a major version update, the Pi config in `~/.pi/agent/` (settings, extensions, prompts) may need adjustments. Check the CHANGELOG for breaking changes.
4. **Network issues**: The update requires internet access to the npm registry. If behind a proxy, ensure `npm config` has the correct proxy settings.
5. **Record the old version**: Before updating, always note the current version (step 1) so rollback is straightforward.
