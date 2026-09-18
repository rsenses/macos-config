---
name: argon-cli
description: Operate Argon projects and tasks through the argon CLI, including project resolution, direct task mutations, Markdown synchronization, conflicts, and the local operation ledger. Use when a user asks to inspect, create, edit, delete, prepare, or synchronize Argon work.
compatibility: Requires the argon launcher, mise with PHP 8.4, and ARGON_API_URL, ARGON_API_KEY, and ARGON_MARKDOWN_PATH in the process environment.
---

# Argon CLI

Use `argon` instead of calling the Argon API directly. Prefer stable JSON output and fail closed on ambiguous or uncertain mutations.

## Preconditions

1. Run `command -v argon` and `argon about`.
2. Never print, inspect, log, or repeat `ARGON_API_KEY`.
3. Argon reads process environment variables only; it does not load `.env`.
4. If setup is missing, report the missing requirement without inventing credentials or endpoints.
5. For exact installed syntax, run `argon help project|task|markdown|operation`. When working in the Argon CLI source repository, use `README.md` as the detailed operating reference.

## Operating rules

- Add `--json` to commands used for decisions or automation. Check both the process exit code and the `ok` field.
- Valid task statuses are only `in-progress`, `blocked`, `done`, and `canceled`.
- Use an explicit `--project=<id-or-code>` when known. Otherwise run `argon project resolve --json` before acting.
- Read the current project/task state before a remote mutation. Use `--if-version=<version>` when the intended revision is known.
- Run only mutations the user requested. Deletion requires an explicit project and `--yes`.
- Never retry a mutation after `uncertain_result` until server state and any local operation record have been inspected.
- Do not expose command output containing sensitive business data unless needed for the user's request.

## Choose a workflow

### Read projects or tasks

```bash
argon project list --json
argon project resolve --json
argon task list --project=<project> --json
argon task search <text> --project=<project> --json
```

Use `--all` only for intentional cross-project reads. `--assigned` on task reads requires `--all`.

### Direct task mutation

Read first, then execute the requested mutation:

```bash
argon task create "<title>" --project=<project> --status=in-progress --json
argon task edit <task-id> --project=<project> --title="<title>" --if-version=<version> --json
argon task edit <task-id> --project=<project> --status=<status> --if-version=<version> --json
argon task delete <task-id> --project=<project> --if-version=<version> --yes --json
```

A creation defaults to `in-progress`. Use `--parent=<task-id>` to create a subtask.

### Markdown synchronization

Treat Argon HTML comments as managed metadata. Do not alter document, project, task, revision, parent, local-operation, or conflict markers.

A local draft has this exact form and must be a root task:

```md
- [in-progress] <title> <!-- argon:new -->
```

`argon:new` marks a local draft; it is not a task status.

Use this sequence:

```bash
argon markdown status --json
argon markdown prepare --yes --json       # only when drafts exist
argon markdown sync --dry-run --json
argon markdown sync --json                # only when the user requested synchronization and the plan is safe
```

Inspect `drafts`, `conflicts`, `planned_creations`, `planned_patches`, and `planned_additions` before the real sync. Deleting a Markdown line does not delete the remote task; use `argon task delete`.

`markdown open` refreshes and opens the editor but does not sync edits afterward. `markdown edit` refreshes, opens a clean document, and syncs changes when the editor exits.

### Conflicts

```bash
argon markdown conflicts --json
argon markdown conflict show <task-id-or-local-uuid> --json
```

Do not choose a winner implicitly. Ask the user when local-versus-server intent is not already explicit, then run one of:

```bash
argon markdown conflict resolve <task-id> --use=local --json
argon markdown conflict resolve <task-id> --use=server --json
```

Creation conflicts may require manual verification.

### Uncertain operations

On `uncertain_result`, stop. Do not rerun `create`, `edit`, `delete`, or `sync`.

1. Re-fetch the relevant project/task state.
2. For Markdown operations, inspect:

   ```bash
   argon operation list --status=uncertain --json
   argon operation show <operation-uuid> --json
   ```

3. Determine whether the server applied the change.
4. Ask before abandoning when intent is not explicit:

   ```bash
   argon operation abandon <operation-uuid> --yes --json
   ```

Abandoning only closes the local record; it does not undo a server change.

## Completion report

Report:

- commands executed, excluding secrets;
- selected project and affected task IDs;
- resulting task status/version;
- dry-run versus applied synchronization;
- conflicts, uncertain results, or skipped mutations.
