# Plan: add-plan-reviewer-subagent
- Status: completed
- Created: 2026-09-10
- Session ID: 01a08a79

## Goal
Add a manually invoked Pi plan-review workflow: a read-only `plan-reviewer` subagent running `openai-codex/gpt-6-astra` at low thinking, plus a `/review-plan` prompt. By default it reviews the active/current saved plan; the prompt accepts an explicit plan path or name for another saved plan. The reviewer must use `grill-with-docs` as its review lens.

Non-goals:
- Do not modify plans, source code, context documents, or ADRs during review.
- Do not make the architect dispatch this reviewer autonomously as part of planning, execution, or finalization.
- Do not change the principal model, default thinking, or unrelated subagents.

## Current Step
Implementation and validation complete. The manual-only policy is expressed in the principal system guidance, architect skill, workflow prompt, and reviewer definition. User-deleted prompts were preserved.

## Spec / Contract

### Known
- The versioned Pi prompt convention is `pi/.pi/agent/prompts/*.md` with YAML frontmatter; `$ARGUMENTS` supports optional prompt arguments.
- The local `pi-subagents` extension discovers every Markdown file in `pi/.pi/agent/extensions/pi-subagents/agents/`, requires explicit provider/model, and launches children with `--no-skills`; read-only agents use `read, grep, find, ls`.
- The current plan resolver is the `get_current_plan` tool: it prefers the current-session plan and otherwise falls back to the latest saved `.ai/plan/*.md` plan.
- Plans created by `create_session_plan` contain Goal, Current Step, Spec / Contract, Tasks, Stop Rules, Validation Policy, and Validation sections.
- `grill-with-docs` is installed under `.agents/skills/grill-with-docs/SKILL.md` in the dotfiles source and is exposed globally after stow. Its useful review behaviors are terminology/domain challenge, concrete scenarios, code contradiction checks, and sparse documentation/ADR consideration.
- The user explicitly requires manual-only activation; the architect must not select this reviewer merely because it would be useful.
- There is no root `CHANGELOG.md`; no changelog file should be created.

### Evidence
- `pi/.pi/agent/prompts/plan.md` documents the persisted plan contract and requires a complete canonical plan.
- `pi/.pi/agent/extensions/pi-subagents/index.ts` loads agent frontmatter and passes explicit `--model`/`--thinking`; children have no automatic skill discovery.
- `pi/.pi/agent/extensions/pi-subagents/README.md` documents the configured agent roster and usage.
- `pi/.pi/agent/extensions/memory.ts` documents `get_current_plan` and its current-session/latest fallback behavior.
- `pi/.agents/skills/grill-with-docs/SKILL.md` defines the grilling review lens.
- `pi/.agents/skills/architect/SKILL.md` and `pi/.pi/agent/APPEND_SYSTEM.md` are the appropriate policy surfaces for preventing autonomous reviewer dispatch.

### Acceptance
- `pi/.pi/agent/extensions/pi-subagents/agents/plan-reviewer.md` exists with valid frontmatter, explicit `model: openai-codex/gpt-6-astra`, `thinking: low`, read-only tools, and explicit instructions to load/use `grill-with-docs`.
- `pi/.pi/agent/prompts/review-plan.md` exists, is discoverable as `/review-plan`, defaults to `get_current_plan`, accepts an explicit saved plan path/name, and dispatches exactly the manual `plan-reviewer` workflow.
- The agent and prompt clearly forbid edits and autonomous use; architect/system guidance states that `plan-reviewer` is only dispatched after an explicit user request or `/review-plan` invocation.
- Local roster/documentation accurately lists the fifth agent and identifies it as manual-only; stale finalization guidance does not claim that no reviewer exists.
- Existing deterministic subagent tests and frontmatter/format checks pass.

## Tasks
- [x] Create the read-only `plan-reviewer` agent definition with Astra/low configuration, explicit grill-with-docs loading, bounded review method, and compact findings output.
- [x] Create `/review-plan` prompt with optional target argument, current-plan resolution, one manual reviewer dispatch, and no autonomous architect path.
- [x] Add manual-only policy to `APPEND_SYSTEM.md` and the architect skill; update subagent README/index roster and finalization wording where the old no-reviewer statement becomes false.
- [x] Validate Markdown frontmatter, exact model/thinking/tools, prompt arguments, manual-only wording, and run existing subagent tests.
- [x] Re-read the complete plan and record validation results.

## Stop Rules
- Stop if the local extension cannot register the new model/thinking combination without changing provider/default settings.
- Stop if making activation manual requires a broader extension architecture change rather than prompt/system policy; report the limitation instead of silently broadening scope.
- Stop after two validation failures without new evidence.

## Validation Policy
- No provider calls.
- Use local parsing/search checks and the existing `pi-subagents` deterministic tests.
- Preserve all unrelated working-tree changes, including the user's deleted prompt files (`checkpoint.md`, `create-issue.md`, `improve-codebase-architecture.md`, and `preflight.md`) and the user's untracked `git-checkpoint.md`; do not restore or replace them.

## Validation
- `git diff --check` — passed.
- `node --experimental-strip-types --test pi/.pi/agent/extensions/pi-subagents/helpers.test.ts` — passed (12 tests).
- `PI_SDK_ROOT=/Users/rubensilvarodriguez/.local/share/mise/installs/node/24.13.0/lib/node_modules/@earendil-works/pi-coding-agent node --test pi/.pi/agent/extensions/pi-subagents/integration.test.mjs` — passed (1 integration test).
- Local no-provider discovery/configuration smoke check — passed: `plan-reviewer` is discoverable and launches with `openai-codex/gpt-6-astra`, `low`, and `read,grep,find,ls`.
- Frontmatter/policy grep and `git diff --check` — passed.
- Preserved user changes: deleted `pi/.pi/agent/prompts/{checkpoint,create-issue,improve-codebase-architecture,preflight}.md` and untracked `pi/.pi/agent/prompts/git-checkpoint.md`; none were restored or replaced.

## Follow-up: compare-skills-prompts-with-matt

### Goal
Review the current Pi skills and prompt templates against the current `mattpocock/skills` repository, then apply only adaptations that improve this harness without replacing deliberate local workflows or restoring user-deleted files.

### Known
- The local workflow deliberately uses `.ai/` session plans and task memory, Pi prompt templates, bounded Luna subagents, and manual-only plan review; these contracts remain authoritative.
- The prior skill-integration plan says not to import strict TDD wholesale and to preserve pragmatic local skills.
- The upstream repository currently groups skills into user-invoked orchestration and model-invoked reusable discipline, and includes useful concepts for tight debugging loops, behavior-focused tests, deep modules, and writing agent-facing documents.
- Local Cloudflare skills are product-specific and have no direct upstream Matt equivalent; preserve them.
- No root `CHANGELOG.md` exists.
- User-deleted prompts remain deleted and must not be restored.

### Evidence
- Upstream source checked at `https://github.com/mattpocock/skills`, current shallow clone `/tmp/mattpocock-skills`, commit `3cca18b368ae95cdbdebbff572ccafa662551015`.
- Upstream references reviewed: `skills/engineering/diagnosing-bugs/SKILL.md`, `skills/engineering/tdd/SKILL.md`, `skills/engineering/codebase-design/SKILL.md`, `skills/engineering/code-review/SKILL.md`, `skills/productivity/writing-for-agents/SKILL.md`, `skills/productivity/grilling/SKILL.md`, `.agents/invocation.md`, and `.agents/writing-docs.md`.
- Local references reviewed: `pi/.agents/skills/{architect,dev,ops,grill-with-docs}/SKILL.md`, `pi/.pi/agent/prompts/{plan,run-plan,debug,isolated-test,finalize,grill-me,security-review,laravel-code-simplifier}.md`, the prior plan `.ai/plan/2026-05-12-019e1ae3-agent-skills.md`, and the current subagent roster.

### Decision
Apply a small, local adaptation rather than importing the upstream catalog:
1. Add a concise `writing-for-agents` skill for maintaining skills, prompts, and agent-facing docs.
2. Add the upstream deep-module vocabulary as a short architecture lens in `architect`, without creating a new orchestration layer.
3. Strengthen `debug` with a red-capable tight loop, minimisation, ranked falsifiable hypotheses, tagged instrumentation, regression coverage, and cleanup.
4. Strengthen `isolated-test` with public-seam, behavior-focused red-green-refactor guidance while keeping the local pragmatic testing posture.
5. Leave the other prompts, Cloudflare skills, deleted files, and subagent architecture unchanged unless validation exposes a contradiction.

### Acceptance
- New/changed guidance is concise, consistent with Pi tools and local `.ai` workflow, and does not require a missing Skill tool or issue tracker.
- No prompt claims autonomous plan review or reintroduces deleted prompts.
- Frontmatter remains valid; `git diff --check` passes; targeted content checks confirm the selected upstream ideas are present.
- `.ai/TASKS.md` marks this comparison task complete and leaves the Herdr notification investigation pending.

### Ordered checklist
- [x] Add the adapted `writing-for-agents` skill.
- [x] Add the deep-module design lens to `architect`.
- [x] Update `debug` with the evidence-first debugging loop.
- [x] Update `isolated-test` with pragmatic TDD guidance.
- [x] Mark the comparison task complete in `.ai/TASKS.md`; preserve the Herdr task.
- [x] Re-read changed files and run `git diff --check` plus frontmatter/content checks.
- [x] Record final validation and remaining recommendations here.

### Validation

- `git diff --check` — passed.
- Frontmatter checks — passed for all local skills and prompt templates; skill names match directory names.
- `node --experimental-strip-types --test pi/.pi/agent/extensions/pi-subagents/helpers.test.ts` — passed (12 tests).
- `PI_SDK_ROOT=/Users/rubensilvarodriguez/.local/share/mise/installs/node/24.13.0/lib/node_modules/@earendil-works/pi-coding-agent node --test pi/.pi/agent/extensions/pi-subagents/integration.test.mjs` — passed (1 integration test).
- Targeted content/preservation checks — passed; upstream ideas are present and user-deleted prompts remain absent.

### Findings not adopted

- The upstream issue-tracker workflows (`setup-matt-pocock-skills`, `to-spec`, `to-tickets`, `wayfinder`, `triage`) were not imported because this harness already has a local `.ai/` plan/task workflow and no configured issue tracker contract.
- The upstream `implement` commit requirement was not imported; local finalization proposes a commit message but does not commit automatically.
- A separate upstream-style `code-review` skill was not added because the local harness already has `coderabbit-review`, `security-review`, and manual `plan-reviewer`; revisit if a standards-vs-spec review is needed without CodeRabbit.
- User-deleted prompts were not restored, including `improve-codebase-architecture`; its useful deep-module idea is represented in the architect lens instead.

### Stop rules
- Stop and preserve the current wording if an upstream idea conflicts with a documented local decision.
- Do not restore deleted prompts or add broad upstream workflows requiring issue-tracker setup.
- Stop after two validation failures without new evidence.
