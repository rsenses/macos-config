# Changelog

All notable changes to this project are documented here using Keep a Changelog and Semantic Versioning.

## [Unreleased]

### Added
- Silent Pi cache diagnostics record per-run keyed request fingerprints, input-block fingerprints, response request IDs and token usage without saving prompts, tool content or credentials. Each run writes and rotates its own local log; the extension adds no tools, notices, model calls or payload changes.

### Fixed
- Legacy plan recovery no longer treats a modern full-UUID plan from another session as a short-ID legacy candidate when sessions share an eight-character prefix; genuine legacy recovery and identity checks remain intact.
- The memory extension suite no longer asserts the pre-humanization plan format. `Current Step` and `Active task` assertions now expect resolved descriptions with their task IDs, and the suite passes again instead of failing on stale expectations.
- `chrome-devtools-mcp` is pinned to `1.10.1` instead of `@latest`. A new release can change the server's instructions and tool list, which rewrites the `mcp_servers` system-prompt section and the request's tool declarations, invalidating the prompt cache mid-session.

### Changed
- Pi's always-on instructions now make token efficiency explicit and point to `ops` for the canonical plan, handoff, and validation contracts. Planning/execution/review/finalization prompts reuse those contracts instead of restating them; read-only Git inspection no longer forces implementation skills, and focused security review uses guidance mode with benefit-driven delegation.
- Planner guidance no longer sets an output-length target and favors verifiable outcomes with only the execution detail needed, while retaining decisions, acceptance, risks and pending work.
- The memory extension now treats the Markdown plan as the sole source of progress. Plan contents are available through explicit tools; remaining lifecycle hooks maintain only the existing status UI and never publish plan text. Session/branch-scoped selection and its confirmations remain intact. Coordinators consult the document at start or resume and update it after accepting verified work, with bounded task briefs for workers.
- Consolidated Pi's full implementation validation contract in `ops` while keeping its fix-then-full-test gate and explicit approvals. `/plan` now records only the brief before invoking its mandatory planner; `/review-plan` uses the supported argument placeholder and never falls back to the newest file. General delegation is benefit-driven, changelog creation follows explicit project/user requirements, and debugging no longer requires a fixed hypothesis count or an arbitrary refactor-size threshold. Per-model startup thinking now records Luna `xhigh` and Sol 6.1 `low` without changing the selected default model or child profiles.
- Pi now requires concise, plain-language plan proposals, progress, blockers, resumptions, and completion reports while retaining detailed execution plans and validation gates.
- Planner profiles now use `openai-codex/gpt-6.1-sol` at `low` by default, with justified `medium` and `high` escalation. Profile names are now `low`, `medium`, and `high`, replacing `habitual`, `diseno`, and `delicado`.
- `/plan` now always delegates design to the `planner` subagent; the selected model no longer writes the plan itself. Outside `/plan`, simple work may still be handled directly without a plan.
- Niche Cloudflare skills (Sandbox SDK family, Wrangler, Durable Objects, Workers best practices, Next.js, Agents SDK, Email Service, Turnstile, Cloudflare One migrations) are no longer advertised in every session; `cloudflare` and `cloudflare-one` route to them by name and path, and each remains loadable with `/skill:<name>`.
- The system prompt keeps a short always-on core: the delegation contract, context budget, and manual-only plan-reviewer rule moved to the `ops` skill, which `APPEND_SYSTEM.md` now points to. Planner optionality is stated once, with `/plan` as the mandatory exception.
- `laravel-code-simplifier` is now a skill loaded on demand; the slash command is a short loader that preserves its behavior-preservation and no-commit rules.
- Pi reports significant prompt-cache misses (`showCacheMissNotices`) so cache behaviour can be measured.
- The plan footer line is now the only plan UI: the widget above the prompt input is gone, so no plan title or status is rendered there.
- The planner approval dialog now shows the coordinator's suggestion instead of a bare model list: the optional planner-only `subagent` argument `profileReason` carries the concrete justification, the dialog leads with `recommended <level>: <reason>` and marks that option `Approve <level> (recommended)`. Every other level stays selectable and cancel stays last; the dialog was and remains mandatory for planner launches.

### Removed
- Duplicate changelog policy injected by the memory extension (it is already in `APPEND_SYSTEM.md`) and duplicate ast-grep usage guidelines (the `ast-grep` skill covers them).
- Stale `design-taste-frontend` and duplicate `security-audit` symlinks from `.pi/agent/skills`; `security-audit` remains in `.agents/skills`.

### Fixed
- The `subagent` tool description hardcoded the planner model, which could drift from `PLANNER_PROFILES`. It is now derived from that table, whose default is the single source of truth, and the planner agent frontmatter is annotated as documentation only.
- Moved memory regression tests outside Pi's extension discovery directory so they are not loaded as extension factories.
- Plan status displays resolve task IDs to descriptions and preserve next-step and blocker explanations instead of relying on opaque task codes.
- Planner launches without an explicit profile fail when low is unavailable instead of proposing a higher thinking level.
