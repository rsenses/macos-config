# Changelog

All notable changes to this project are documented here using Keep a Changelog and Semantic Versioning.

## [Unreleased]

### Changed
- Pi now requires concise, plain-language plan proposals, progress, blockers, resumptions, and completion reports while retaining detailed execution plans and validation gates.
- Planner profiles now use `openai-codex/gpt-6.1-sol` at `low` by default, with justified `medium` and `high` escalation. Profile names are now `low`, `medium`, and `high`, replacing `habitual`, `diseno`, and `delicado`.
- `/plan` now always delegates design to the `planner` subagent; the selected model no longer writes the plan itself. Outside `/plan`, simple work may still be handled directly without a plan.
- Niche Cloudflare skills (Sandbox SDK family, Wrangler, Durable Objects, Workers best practices, Next.js, Agents SDK, Email Service, Turnstile, Cloudflare One migrations) are no longer advertised in every session; `cloudflare` and `cloudflare-one` route to them by name and path, and each remains loadable with `/skill:<name>`.
- The system prompt keeps a short always-on core: the delegation contract, context budget, and manual-only plan-reviewer rule moved to the `ops` skill, which `APPEND_SYSTEM.md` now points to. Planner optionality is stated once, with `/plan` as the mandatory exception.
- `laravel-code-simplifier` is now a skill loaded on demand; the slash command is a short loader that preserves its behavior-preservation and no-commit rules.
- Pi now reports significant prompt-cache misses (`showCacheMissNotices`) so cache behaviour can be measured while the memory extension rebuilds plan context.
- The plan footer line is now the only plan UI: the widget above the prompt input is gone, so no plan title or status is rendered there.

### Removed
- Duplicate changelog policy injected by the memory extension (it is already in `APPEND_SYSTEM.md`) and duplicate ast-grep usage guidelines (the `ast-grep` skill covers them).
- Stale `design-taste-frontend` and duplicate `security-audit` symlinks from `.pi/agent/skills`; `security-audit` remains in `.agents/skills`.

### Fixed
- The `subagent` tool description hardcoded the planner model, which could drift from `PLANNER_PROFILES`. It is now derived from that table, whose default is the single source of truth, and the planner agent frontmatter is annotated as documentation only.
- The memory extension suite no longer asserts the pre-humanization plan format. `Current Step` and `Active task` assertions now expect resolved descriptions with their task IDs, and the suite passes again instead of failing on stale expectations.
- Moved memory regression tests outside Pi's extension discovery directory so they are not loaded as extension factories.
- Plan status displays resolve task IDs to descriptions and preserve next-step and blocker explanations instead of relying on opaque task codes.
- Planner launches without an explicit profile fail when low is unavailable instead of proposing a higher thinking level.
