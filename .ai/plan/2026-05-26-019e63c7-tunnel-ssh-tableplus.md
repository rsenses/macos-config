# Plan: tunnel-ssh-tableplus
- Status: in-progress
- Created: 2026-05-26
- Session ID: 019e63c7

## Goal
Diagnose why the SSH tunnel LaunchAgent does not leave local ports up for TablePlus and align the SSH agent/config with launchd.

## Current Step
Validate the tunnel auth path after switching the tunnel hosts to the Bitwarden SSH agent socket.

## Spec / Contract
- The LaunchAgent should start the tunnel script.
- The tunnel script should not depend on a stale hardcoded SSH_AUTH_SOCK.
- SSH config for tunnel hosts should use the live agent socket, not missing `IdentityFile` paths.

## Tasks
- [x] Inspect `tunnel-ssh.sh`, LaunchAgent plist, and logs.
- [x] Remove hardcoded SSH_AUTH_SOCK from the script.
- [x] Remove SSH_AUTH_SOCK override from the LaunchAgent plist.
- [x] Switch tunnel host SSH config entries to `IdentityAgent /Users/rubensilvarodriguez/.bitwarden-ssh-agent.sock`.
- [ ] Confirm the tunnels come up and TablePlus can connect.

## Stop Rules
Stop if the Bitwarden agent/socket itself is unavailable or still does not answer SSH auth requests.

## Validation Policy
- `bash -n bin/.local/bin/tunnel-ssh.sh`
- `plutil -lint ~/Library/LaunchAgents/com.ruben.tunnel-ssh.plist`
- Spot-check `ssh -G` for the tunnel hosts.
