# Project Memory

Durable project knowledge, decisions, preferences, and recurring lessons.

## Stable Preferences

- Prefer simple, direct implementations.
- Prefer framework-native and project-native solutions.
- Avoid unnecessary abstractions.
- Do not duplicate framework guarantees.
- Use explicit complexity triage before research: simple/local tasks should stop after nearby code inspection; cross-cutting, risky, or API-heavy tasks should investigate further.

## Project Decisions

- Memory POC: pending work lives in `.ai/TASKS.md`; simple tasks are one-line checkboxes and complex tasks link to plans with wiki links like `[[.ai/plan/file.md]]`.
- Memory POC: use one current session plan file (`.ai/plan/YYYY-MM-DD-<session-id>-<short-slug>.md`) and update it across turns instead of creating a new plan per interaction; session id prevents duplicates, slug keeps filenames readable.
- Validation:
- Remaining:
- Notes:
- For execution prompts like `run-plan` and `fix-plan`, a bare “use orchestrator” line is not enough; they should explicitly tell the agent to delegate bounded pieces through orchestrator when the task is multi-file or multi-step.
- Pi extensions always live in `pi/.pi/agent/extensions/` for this repo.
- `pi-rtk` only rewrites `bash` tool calls and `!<cmd>` shell commands; `!!<cmd>` is intentionally excluded, and the session toggle is in-memory only.
- When finalizing commits, prefer the task's user-facing goal or current session plan Goal / Expected Changes over low-level implementation wording when choosing the commit summary.
- Agent workflow: the main agent owns validation strategy; worker delegations should include an explicit validation policy and workers should not add tests or run broad suites unless asked.
- Agent workflow: for small changes, prefer existing repo patterns before source-driven docs or code review; treat those skills as opt-in for unfamiliar or risky diffs.
- Global Pi preference: prefer `fd` over `find` for file discovery; use `find` only when `fd` is unavailable or POSIX-specific behavior is required.
- UI feedback: for post-response warnings based on final context usage, prefer `agent_end` with `ctx.ui.notify(..., "error")` so the message appears after the agent finishes and renders in red.
- Memory extension note: `pi/.pi/agent/extensions/memory.ts` currently injects `.ai/MEMORY.md`, `.ai/TASKS.md`, and daily notes into context, but durable persistence still depends on prompt/model flow; daily files are created automatically, not populated automatically.
- Persistence lesson: prompt wording needs to say "write the file" explicitly; advisory phrasing like "update memory" is easier for the model to narrate than to execute.
- Extension pitfall: when editing `memory.ts` template literals, escape literal markdown backticks inside the injected prompt; otherwise the extension can fail to parse on load.
