---
name: local-dev-server
description: Operate, debug, test, or modify the repository's `bin/.local/bin/dev` command and its local PHP/Node servers behind Caddy.
---

# Local development server: `dev`

Use this skill when the task involves `bin/.local/bin/dev`, `tests/test_dev.py`, local Caddy routes, or the lifecycle of a project server managed by this command. Keep the existing `dev` skill for general implementation, testing, framework documentation, and debugging; this skill is the command-specific contract.

## Command contract

```text
dev up [folder]
dev down [folder]
dev reload [folder]
dev status [folder]
dev down-all
```

- With no folder, resolve the current directory. With a folder name, prefer `$HOME/dev/www/<name>`; otherwise accept an existing path.
- For Git projects, resolve the repository root. The domain is `<repository-name>.<suffix>`; the default suffix is `test`.
- `up` allocates the first free port from `8000` through `8999`, starts the detected server on loopback, writes a Caddy snippet, then reloads Caddy.
- `down` removes the project's route and stops its verified server. `reload` is `down` followed by `up`, and must not start a replacement if `down` fails.
- `status` is read-only: it reports project, domain, port, server type, and log information. `down-all` stops every state file managed by the command and reloads Caddy once.

## Supported servers

Detection is deterministic and ordered:

1. `artisan` at the project root → Laravel (`php artisan serve`).
2. `index.php` in the selected `public/` or `web/` root → plain PHP (`php -S`).
3. `package.json` with a non-empty `scripts.dev`, with `node` available → Node (`npm run dev`).

The selected server binds to `127.0.0.1`. Node receives `--host 127.0.0.1 --port <port>`. A PHP `web/` or `public/` directory is preferred as the document root; a PHP `.ht.router.php` is passed through when present.

## Caddy and local state

Defaults can be redirected for tests or another machine:

| Variable | Default |
| --- | --- |
| `DEV_SITES_DIR` | `$HOME/dev/caddy-sites` |
| `DEV_CADDYFILE` | `/opt/homebrew/etc/Caddyfile` |
| `DEV_DOMAIN_SUFFIX` | `test` |
| `DEV_CADDY_ADMIN` | `http://localhost:2019` |
| `DEV_STATE_PREFIX` | `/tmp/dev` |
| `DEV_LOCK_DIR` | `${DEV_STATE_PREFIX}.lock` |

Each generated snippet proxies the domain and configured aliases to `127.0.0.1:<port>`, sets the forwarded host/protocol headers, and uses Caddy's internal TLS issuer. Aliases are read from `.config/caddy` using `ALIASES=...`; values may be space- or comma-separated and receive the domain suffix when missing.

The command stores a per-project `.state` and `.log` beside `DEV_STATE_PREFIX`, keyed by a SHA-256 hash of the resolved project path. State records the project, hosts, port, PID, process start time, server type, working directory, and process group. Read state through `dev status`; do not infer ownership from a PID alone.

## Safety invariants

- Mutation commands serialize through the lock. Never manually remove a live lock unless its recorded owner is definitely gone.
- Never kill a process solely because its PID appears in state. Verify command, port, recorded start time, and, when available, working directory. For Node, also verify the listener is in the owned process tree/group.
- Never stop an unrelated listener or delete an unrelated Caddy snippet. Cleanup only matches the managed upstream `127.0.0.1:<port>` or a complete generated host token.
- On `up`, remove stale routes before replacement, start and verify the server before publishing its new upstream, and clean state/snippet/processes on failure.
- If another active state owns an overlapping domain, preserve the old instance unless the user explicitly confirms replacement.
- Prefer the command's `down`/`down-all` lifecycle over ad-hoc `kill`, `rm`, or Caddy edits. A Caddy-unreachable warning is distinct from a successful Caddy reload failure; preserve and report that distinction.

## Investigation and changes

1. Read the relevant part of `bin/.local/bin/dev` and the corresponding tests before changing behavior.
2. Preserve the `DEV_*` seams: tests must not touch the real Caddyfile, `$HOME/dev/caddy-sites`, `/tmp/dev`, user servers, or `sudo`.
3. Keep process identity checks conservative. If ownership cannot be proven, fail safely and leave the unrelated process alive.
4. After changes, run syntax validation and the complete repository test command. Inspect generated state/snippet cleanup and the diff; do not broaden the change into generic shell cleanup.

## Verification

From the repository root:

```sh
bash -n bin/.local/bin/dev
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests
```

The isolated suite is in `tests/test_dev.py`; it fakes `curl`, `caddy`, `sudo`, `lsof`, `ps`, `php`, and `npm`, and creates only its own temporary server processes. When the caller's environment overrides `DEV_DOMAIN_SUFFIX`, set `DEV_DOMAIN_SUFFIX=test` for the repository's default-domain assertions rather than changing the script or tests.
