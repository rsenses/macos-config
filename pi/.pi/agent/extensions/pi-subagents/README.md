# Pi subagents

Four bounded roles; the principal coordinates and verifies acceptance.

| Agent | Model / thinking | Tools |
|---|---|---|
| scout | `openai-codex/gpt-5.6-luna` / **low** | read, grep, find, ls |
| researcher | `openai-codex/gpt-5.6-luna` / **medium** | codex-research, web_fetch |
| planner | `openai-codex/gpt-5.6-luna` / **high** | read, grep, find, ls |
| worker | `openai-codex/gpt-5.6-luna` / **medium** | read, write, edit, grep, find, ls, safe_bash, ast_grep, web_fetch |

**Principal stays Luna/max.** Normally use no child or one child; at most two genuinely independent tasks. File count alone is not a reason to delegate. Planner is optional. Children cannot delegate; missing substantial evidence is returned to the principal as a blocker.

Scout/planner deliberately lack shell, edit and mutating AST tools. Worker has local discovery, execution, structural editing and documentation retrieval. Researcher has real search, not merely URL extraction. LSP is not injected into every child: use the principal's configured server when semantic evidence is needed, and pass that evidence in the brief.

## Usage

```json
{
  "agent": "worker",
  "thinking": "high",
  "task": "Goal: ... Known: ... Evidence: ... Acceptance: ... Checks: ... Stop: ..."
}
```

`agent` and `task` are required. `cwd` and `thinking` are optional. Invocation overrides accept `low`, `medium`, `high`, `max`; unsupported model/effort combinations fail before spawn instead of silently clamping. No automatic provider fallback or paid subscription activation occurs.

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

The prefix `execution=complete|partial|failed|cancelled|timed_out` describes the **process/protocol**, not task correctness. A successful process may report task `Status: blocked`. Length-limited, deferred, empty and commentary-only responses do not certify completion. Partial evidence and error text are preserved; failed/cancelled/timed-out execution sets Pi's error flag through `tool_result`.

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

The integration test loads the installed Pi SDK and actual tools, runs a fixture Pi subprocess, verifies error propagation/usage/allowlists and tests bounded web recovery and task-context injection. It never calls a model or external website. Node 24 and the installed pinned extension dependencies are expected.
