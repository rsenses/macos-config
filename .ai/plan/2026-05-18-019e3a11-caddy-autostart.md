# Caddy autostart for `dev up`

## Goal

Fix `bin/.local/bin/dev up` so `https://<site>.test` works even when Caddy is not already running.

## Expected behavior

- `dev up` should ensure the local Caddy admin/API is available.
- If Caddy is down, the script should start it before claiming success.
- The PHP server and Caddy should both be running when `dev up` exits OK.

## Current evidence

- `127.0.0.1:8010` works.
- `cobra.wyrko.es.test` resolves to `127.0.0.1`.
- Caddy admin `http://localhost:2019/config/` is down during the failure.
- No process is listening on 80/443.
- `dev up` only starts Caddy when the per-site snippet does not exist.
- Caddy needs `sudo` to start on this machine.

## Plan

1. Make `dev up` start/reload Caddy whenever needed, not only on first snippet creation.
2. Verify the script still handles the normal happy path.
3. Update project notes with the fix and validation.

## Status

- Script updated to fall back to plain `sudo caddy ...` when Caddy is down.
- Pending: user confirmation that `dev up` now brings Caddy up automatically.
