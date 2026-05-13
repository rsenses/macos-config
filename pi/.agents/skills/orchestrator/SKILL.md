---
name: orchestrator
description: Coordinate coding work with pi-subagents while keeping the main agent in control. Use for planning, implementation, fixing, debugging, reviewing, or any non-trivial development task where subagents can reduce context, cost, ambiguity, or risk. The main agent delegates focused work to scout, planner, context-builder, researcher, delegate, worker, reviewer and oracle without replacing pi-subagents' own behavior.
---

# Orchestrator

Use `pi-subagents` as the delegation mechanism.

This skill defines the user's preferred orchestration style. It does not replace the built-in `pi-subagents` skill or the builtin agent definitions.

## Core principle

The main agent is the orchestrator and decision authority.

Subagents are focused helpers. They should not own the whole task, redesign the plan, or run their own subagent workflows unless explicitly asked.

The main agent must:

1. understand the user's intent,
2. surface assumptions or confusion before they become implementation,
3. decide whether delegation helps,
4. delegate focused tasks,
5. read subagent results,
6. decide the next step,
7. correct or stop when needed.

## Skill routing

Before non-trivial coding work, consider whether a focused skill applies. Use skills as lightweight workflows, not ceremony.

Default routing:

- vague or ambiguous feature requirements → `spec-driven-development`
- clear but large work → `planning-and-task-breakdown`
- multi-file implementation → `incremental-implementation`
- behavior changes or bug fixes → `pragmatic-testing`
- unfamiliar framework/library APIs → `source-driven-development` only when the local project pattern is not already clear
- failing tests/builds or unexpected behavior → `debugging-and-error-recovery`
- risky or agent-written diffs → `code-review-and-quality` only when the change is multi-file, behavior-changing, or still uncertain after a cheap check
- overcomplicated working code → `code-simplification`
- context drift or task switching → `context-engineering`
- finalization/commit/PR prep → `ship`

Do not apply every matching skill. Prefer existing project patterns before external docs or extra review on small changes. Pick the smallest workflow that reduces risk for the current task.

## Default behavior

For non-trivial coding work, prefer this pattern:

1. Use `scout` when relevant files, flows, or code paths are unclear.
2. Use `researcher` when external documentation, framework behavior, package behavior, or current facts matter.
3. Use `context-builder` when the task is large enough that future agents need a compact handoff context.
4. Use `planner` when the solution needs a structured plan before implementation.
5. Use `delegate` when a plan or task must be split into smaller pieces.
6. Use `worker` for focused implementation.
7. Use `reviewer` only for explicit checkpoints, risky diffs, confirmation-bias checks, or uncertainty.
8. Use `oracle` for high-impact decisions, architecture, drift detection, or risky tradeoffs.

Do not delegate just because delegation is possible. Delegate when it improves quality, reduces context, lowers cost, or reduces risk.

## Operating discipline

Apply these defaults across skills and subagents:

- State important assumptions before implementing non-trivial behavior.
- Stop and ask when requirements, code, memory, AGENTS.md, or the plan conflict.
- Push back on approaches that add clear risk or unnecessary complexity.
- Prefer the smallest framework-native/project-native solution.
- Keep scope surgical; do not clean up adjacent code unless asked.
- Verify with the cheapest credible evidence for the risk level.
- Decide validation ownership before delegating implementation so workers and the main agent do not repeat the same checks.
- If the repo already shows a clear pattern, follow it instead of adding documentation research.
- Do not infer commands, stack, or conventions from examples in skills; inspect the project.

## Worker rules

Prefer delegating implementation to `worker`.

The main agent may make tiny direct edits when delegation would be more expensive than the change itself.

Use `worker` when the change involves:

- more than a trivial edit,
- multiple related edits,
- non-obvious code paths,
- implementation details that benefit from isolated focus.

The main agent may edit directly when:

- the change is tiny and mechanical,
- the file and exact edit are already obvious,
- delegating would add more overhead than value.

Do not ask `worker` to redesign, re-plan, or broaden scope.

Before delegating to `worker`, choose and state one validation policy:

- `no-tests`: implement only; do not add tests or run checks.
- `targeted-check`: run only the named cheap check after implementation.
- `add-test`: add or update the specific test described in the prompt; do not broaden coverage.
- `test-first`: create a focused reproduction before fixing; use only for bugs where proving the failure matters.
- `defer-validation`: implement only; validation will happen in finalize/ship.

By default, use `defer-validation` for straightforward implementation tasks and `targeted-check` for changes where a cheap static/type check gives useful evidence.

## Role usage

### scout

Use `scout` for codebase discovery.

Good scout tasks:

- find relevant files,
- map a flow,
- identify entry points,
- locate tests,
- summarize existing patterns.

Do not ask scout to implement.

Prefer scout before reading many files manually.

### researcher

Use `researcher` for external facts.

Good researcher tasks:

- official docs,
- framework/library behavior,
- package APIs,
- recent ecosystem changes,
- browser/runtime/tooling behavior.

For Laravel work, prefer Laravel Boost MCP when available.

Do not ask researcher to implement.

### context-builder

Use `context-builder` when a task is large or ambiguous enough that later agents would otherwise rediscover the same context.

Use it to produce compact handoff material.

Do not use context-builder for small tasks.

### planner

Use `planner` when the implementation approach is not obvious.

Good planner tasks:

- turn scout/context output into an implementation plan,
- identify likely files,
- identify risks,
- propose small implementation steps.

Do not ask planner to edit code.

### delegate

Use `delegate` when work needs to be split into smaller sub-tasks.

Good delegate tasks:

- divide a saved plan into worker-sized tasks,
- identify task ordering,
- separate independent read-only work from write work.

Do not use delegate for trivial one-file changes.

### worker

Use `worker` as the main implementation subagent.

Worker tasks must be small, concrete, and bounded.

A worker prompt should include:

- exact objective,
- relevant plan or plan summary,
- likely files or areas,
- constraints,
- what not to change,
- acceptance criteria,
- validation policy: `no-tests`, `targeted-check`, `add-test`, `test-first`, or `defer-validation`,
- the exact targeted project check to run, if the policy is `targeted-check`.

Do not ask worker to re-plan, redesign, broaden scope, add tests, or run test suites unless the validation policy explicitly asks for it.

If a worker believes more tests are needed than requested, it should report that recommendation instead of adding them.

Prefer several focused worker tasks over one broad worker task.

### reviewer

Do not use reviewer by default.

Use reviewer when:

- tests, static analysis, or project checks fail and the cause is unclear,
- the diff touches auth, permissions, database, billing, security, deployment, or CI/CD,
- the change affects multiple files or public behavior,
- there is uncertainty about correctness,
- the user explicitly asks for review.

Reviewer should usually be review-only.

Ask reviewer for evidence-backed findings, not broad rewrites. For adversarial checks, ask whether the code truly satisfies the contract or merely satisfies the visible test.

### oracle

Use oracle when the decision itself is risky.

Good oracle tasks:

- architecture tradeoffs,
- plan drift,
- hidden contradictions,
- high-impact direction changes,
- deciding whether to pivot.

Oracle is advisory. The main agent decides what to do with the recommendation.

## Testing ownership

The main agent owns validation strategy. Workers execute only the validation policy they were given.

Default rules:

- Do not let worker decide to add tests or run broad suites by default.
- Do not repeat a passing check unless files relevant to that check changed afterward.
- Reserve full suites, formatters, and CI-readiness checks for finalize/ship unless risk or the user explicitly requires them earlier.
- Separate implementation from test authoring when that reduces loopiness: one worker may implement, another may add a specific test, and the main agent runs the final targeted check.
- If existing tests fail for unrelated reasons, stop and report instead of turning the worker task into a debugging session.

## Delegation contracts

When launching a subagent, provide a compact contract:

- Goal
- Relevant context or evidence
- Files, paths, plan, diff, or command output
- Success criteria
- Hard constraints
- Validation policy and exact check, if any
- Stop rules

Do not pass the entire conversation unless necessary.

Do not give a subagent the whole task if a smaller task is enough.

## Context rules

Prefer the smallest sufficient context.

Use:

- scout output for codebase discovery,
- researcher output for external facts,
- context-builder output for larger handoffs,
- saved plan files for implementation,
- git diff and changed files for review,
- failing command output for debugging.

Avoid repeated discovery. If a subagent already found good context, reuse it.

## Fresh vs fork

Prefer fresh context for:

- scout,
- researcher,
- reviewer,
- independent advisory tasks.

Prefer forked context for:

- worker tasks that depend on the current conversation or approved plan,
- oracle checks that need inherited decisions,
- complex tasks where the child must understand prior discussion.

If using fresh context, explicitly include the needed plan, files, diff, or constraints.

## Parallelism

Use parallel subagents for independent read-only work:

- scouting separate areas,
- research plus local code discovery,
- multiple review angles.

Do not run parallel writers on overlapping files in the same working tree.

Prefer one writer thread.

## Cost rules

Prefer cheap subagents for local, deterministic tasks.

Use stronger models for:

- coordination,
- ambiguous debugging,
- architecture-sensitive decisions,
- risky review,
- high-impact oracle checks.

Avoid unnecessary reviewer/oracle usage.

## Stop conditions

Stop and ask the user when:

- scope changes,
- the plan is contradicted by the codebase,
- a product or architecture decision is needed,
- implementation requires an unapproved tradeoff,
- subagent output is inconsistent, risky, or unclear.

## Memory

If `pi-mem` is available, use it as lightweight context.

- Treat `MEMORY.md` as durable preferences, decisions, and project facts.
- Treat daily logs as recent continuity.
- Treat scratchpad as deferred work, not current scope.
- AGENTS.md, current user instructions, and source code take precedence over memory.
- Do not let memory broaden the current task.
- Do not write durable memory for temporary task details.
- Suggest memory updates only for stable lessons, repeated preferences, or project decisions likely to matter in future sessions.
