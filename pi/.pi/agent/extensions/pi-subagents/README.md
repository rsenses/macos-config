# Pi subagents

Five bounded roles; the principal coordinates and verifies acceptance. `plan-reviewer` is manual-only and must never be dispatched solely by the architect's own decision.

| Agent | Model / thinking | Tools |
|---|---|---|
| scout | `opencode-go/deepseek-v4.1-flash` / **high** | read, grep, find, ls |
| researcher | `openai-codex/gpt-5.6-luna` / **medium** | codex-research, web_fetch |
| planner (default) | `openai-codex/gpt-5.6-luna` / **high** | read, grep, find, ls — UI approval required; optional `profile` (see below) |
| worker | `opencode-go/glm-5.3-flash` / **high** | read, write, edit, grep, find, ls, safe_bash, ast_grep, web_fetch |
| plan-reviewer | `openai-codex/gpt-6-astra` / **low** | read, grep, find, ls |

### Planner profiles

The `subagent` tool accepts an optional `profile` argument for the planner only. A profile pins **both** the exact model and the thinking level; there is no fallback between models and no silent clamping.

| Profile (argument) | Display label | Model | Thinking |
|---|---|---|---|
| `habitual` | habitual | `openai-codex/gpt-5.6-luna` | high |
| `diseno` | diseño | `openai-codex/gpt-5.6-sol` | medium |
| `delicado` | delicado | `openai-codex/gpt-6-astra` | low |

Profile rules:

- Profiles are planner-only; passing one to any other agent fails before spawn.
- Unknown profile names fail with the available list.
- A profile combined with an explicit `thinking` that differs from the profile's level fails; pass the profile's own level if you must be explicit.
- The exact model must exist in the model registry and, when the session has non-empty scoped models (`enabledModels`), must be inside that scope; an empty scope accepts any registry model. An out-of-scope or unsupported selection fails with a clear error — never a fallback.
- The coordinator explains the brief, reason and proposed exact model/thinking; the launcher obtains the single model approval in its host UI, with options to approve, choose another available profile, or cancel. Do not ask a duplicate question in `/plan`. This applies when `profile` is omitted too; headless/print/json execution is blocked before spawn. Pre-aborted calls do not open UI; aborting a pending dialog dismisses it without launching. Cancellation returns normal `cancelled` and ends that attempt: no direct planning, alternative profile/role or retry. Implementation authorization remains separate.
- The selected profile name/label and the exact effective model/thinking are recorded in the result details and progress UI so approval and recovery show what was requested and what launched.
- `openai-codex/gpt-5.6-sol` is explicitly allowlisted in `pi/.pi/agent/settings.json` `enabledModels` solely to make the `diseno` profile selectable; principal defaults (`defaultProvider`/`defaultModel`/`defaultThinkingLevel`) are unchanged.

**Principal stays Luna/max.** Normally use no child or one child; at most two genuinely independent tasks. File count alone is not a reason to delegate. Planner is optional. Children cannot delegate; missing substantial evidence is returned to the principal as a blocker.

**Plan format.** The ops skill defines the canonical `## TL;DR`, `## Current Step` (Current/Next/Blockers) and top-level Tn Tasks format. The coordinator saves and updates the full plan; planner only proposes it. `select_session_plan` and `newPlan=true` confirm in their tool UI before changing selection; cancellation preserves existing state and selecting a plan does not approve implementation. The selection belongs to the full active branch, surviving compaction; legacy filename recovery is limited to sessions with no selection records anywhere.

**Role contracts.** Planner is read-only: no edits, provider calls, or nested delegation; it reuses the supplied Known/Evidence and returns one executable checklist (exact files/symbols, dependencies, acceptance, checks) with explicit unresolved questions or `blocked` instead of guesses. Worker executes one bounded implementation slice: it preserves unrelated changes, security/data-integrity invariants, user decisions and changelog policy, never delegates or invents missing dependencies, and returns exactly `Status`, `Changes`, `Evidence`, `Checks`, `Unresolved`. The `execution=` prefix below describes the process/protocol; it never certifies task acceptance — the principal verifies acceptance locally, and `blocked` is a recoverable outcome, not success.

Scout/planner deliberately lack shell, edit and mutating AST tools. Worker has local discovery, execution, structural editing and documentation retrieval. Researcher has real search, not merely URL extraction. LSP is not injected into every child: use the principal's configured server when semantic evidence is needed, and pass that evidence in the brief.

## Usage

```json
{
  "agent": "worker",
  "thinking": "high",
  "task": "Goal: ... Known: ... Evidence: ... Acceptance: ... Checks: ... Stop: ..."
}
```

`agent` and `task` are required. `cwd` and `thinking` are optional; `profile` is optional and planner-only (see above). Invocation overrides accept `low`, `medium`, `high`, `max`; unsupported model/effort combinations fail before spawn instead of silently clamping. No automatic provider fallback or paid subscription activation occurs. A planner call without an explicit profile is still an approval-gated call; omission never auto-approves or bypasses model validation.

Use low for lookup, medium for contained implementation/synthesis, high for difficult or risky reasoning. Max is available explicitly, not the child default. A small local smoke comparison is recorded in `.ai/audits/2026-09-06-pi-harness/IMPLEMENTATION.md`; it is not an autonomous-coding benchmark. Flash remains a candidate after Go access is restored, not a configured dependency that currently fails.

## Dependencies and tool loading

- `web_fetch` and `ast_grep` are sibling **local extensions** in this repository.
- `safe_bash` is shipped in `tools/safe-bash.ts`: a command filter, **not a sandbox**.
- `codex-research` loads the pinned `pi-gpt-search` package from `~/.pi/agent/npm/node_modules/pi-gpt-search/src/index.ts`; it requires the existing Codex search credentials, independently of the researcher's model.
- Unknown tools and missing extension files fail explicitly. The unified `--tools` allowlist also restricts other tools registered by the same extension; loading search does not grant the deprecated `web` alias.

Custom tools require a mapping in `CUSTOM_TOOL_EXTENSIONS`. Native read/write/edit/bash/grep/find/ls need no extension. Do not give writers overlapping file ownership.

## Isolation and prompts

Children run with `--mode json -p --no-session --no-skills --no-extensions`, selected extension paths/tools, explicit `--model` and `--thinking`, and no prompt templates or themes. Conversation history and global APPEND_SYSTEM are not copied.

The shared `SYSTEM.md` replaces Pi's generic default only when neither the project's `.pi/SYSTEM.md` nor the global `~/.pi/agent/SYSTEM.md` exists. Explicit custom system prompts remain authoritative. Role text is appended; AGENTS.md/CLAUDE.md discovery remains enabled. The lean prompt avoids mandatory tours through unrelated Pi manuals.

Briefs must include relevant user decisions, existing changes, invariants, validation/changelog requirements and applicable skill references. Children share filesystem and inherited process environment; cwd and allowlists are **not security isolation**.

## Limits and observability

Optional `config.json` beside `index.ts`:

```json
{
  "maxConcurrency": 2,
  "timeoutMs": 600000,
  "maxOutputBytes": 16384,
  "maxOutputLines": 200
}
```

These are the defaults. Values must be positive; counts and output limits must be integers. The deadline includes the queue. Cancellation removes queued work or terminates the launched process group with TERM/KILL escalation. Processes that deliberately detach into another group are outside this guarantee; this is not a sandbox. Cleanup waiting is bounded.

Output is clipped by UTF-8 bytes and lines; full captured text is saved to a mode-0600 temporary artifact, with its path returned. Artifacts survive the invocation for recovery and remain until system/user cleanup. The presentation byte limit is additionally capped at 1 MiB; incomplete JSON event buffers are capped at 16 MiB. Recent tool previews and stderr are bounded.

The prefix `execution=complete|partial|failed|cancelled|timed_out` describes the **process/protocol**, not task correctness. A successful process may report task `Status: blocked`. Length-limited, deferred, empty and commentary-only responses do not certify completion. Partial evidence and error text are preserved; failed/timed-out execution sets Pi's error flag through `tool_result`, while cancellation is a normal outcome.

Usage is returned at the top level for Pi accounting, including reported nested-tool/compaction usage without counting detail trees twice. Details record requested/effective model, validated thinking, queue and total duration. Unreported backend costs (e.g. search) remain unknown, not zero.

## UI and extension API

Ctrl+O toggles a compact progress display and expanded task/output. Progress includes tool count, duration, context and usage.

Extensions may register definitions via `globalThis.__pi_subagents.registerAgent(config)` and remove them with `unregisterAgent(name)`. Required fields: name, description, tools, explicit provider/model, thinking, systemPrompt, filePath. Names must be simple alphanumeric/hyphen/underscore segments. Tool mappings must exist; nested `subagent` is rejected, including for dynamically registered definitions.

## Tests (no provider calls)

```sh
node --experimental-strip-types --test pi/.pi/agent/extensions/pi-subagents/helpers.test.ts
PI_SDK_ROOT=/absolute/path/to/pi-coding-agent \
  node --test pi/.pi/agent/extensions/pi-subagents/integration.test.mjs
```

The integration test loads the installed Pi SDK and actual tools, runs a fixture Pi subprocess, verifies error propagation/usage/allowlists and tests bounded web recovery and task-context injection. Memory regressions bind the extension's appendEntry to a real temporary SessionManager, test selection writes/reopening and full-branch versus compacted/abandoned-branch state. Pending dialogs resolve only on an explicit fixture decision or the installed opts.signal cancellation contract; no child/file/pointer may be created while approval waits. It never calls a model or external website. Node 24 and the installed pinned extension dependencies are expected.
