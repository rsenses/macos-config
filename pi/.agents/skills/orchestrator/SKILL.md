---
name: orchestrator
description: Coordinate coding work with pi-subagents while keeping the main agent in control. Use for planning, implementation, fixing, debugging, reviewing, or any non-trivial development task where subagents can reduce context, cost, ambiguity, or risk. The main agent delegates focused work to scout, planner, context-builder, researcher, delegate, worker, reviewer, debugger, and oracle without replacing pi-subagents' own behavior.
---

# Orchestrator

Use `pi-subagents` as the delegation mechanism.

This skill defines the user's preferred orchestration style. It does not replace the built-in `pi-subagents` skill or the builtin agent definitions.

## Core principle

The main agent is the orchestrator and decision authority.

Subagents are focused helpers. They should not own the whole task, redesign the plan, or run their own subagent workflows unless explicitly asked.

The main agent must:

1. understand the user's intent,
2. decide whether delegation helps,
3. delegate focused tasks,
4. read subagent results,
5. decide the next step,
6. correct or stop when needed.

## Default behavior

For non-trivial coding work, prefer this pattern:

1. Use `scout` when relevant files, flows, or code paths are unclear.
2. Use `researcher` when external documentation, framework behavior, package behavior, or current facts matter.
3. Use `context-builder` when the task is large enough that future agents need a compact handoff context.
4. Use `planner` when the solution needs a structured plan before implementation.
5. Use `delegate` when a plan or task must be split into smaller pieces.
6. Use `worker` for focused implementation.
7. Use `debugger` for unclear failures, failing commands, or bug investigation.
8. Use `reviewer` only for explicit checkpoints, risky diffs, or uncertainty.
9. Use `oracle` for high-impact decisions, architecture, drift detection, or risky tradeoffs.

Do not delegate just because delegation is possible. Delegate when it improves quality, reduces context, lowers cost, or reduces risk.

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
- whether PHPStan or a targeted check should be run.

Do not ask worker to re-plan, redesign, or broaden scope.

Prefer several focused worker tasks over one broad worker task.

### reviewer

Do not use reviewer by default.

Use reviewer when:

- tests or PHPStan fail and the cause is unclear,
- the diff touches auth, permissions, database, billing, security, deployment, or CI/CD,
- the change affects multiple files or public behavior,
- there is uncertainty about correctness,
- the user explicitly asks for review.

Reviewer should usually be review-only.

Ask reviewer for evidence-backed findings, not broad rewrites.

### debugger

Use debugger when something fails and the cause is unclear.

Good debugger tasks:

- analyze failing PHPStan output,
- analyze failing tests,
- trace a bug,
- identify likely root cause.

Do not use debugger for straightforward implementation.

### oracle

Use oracle when the decision itself is risky.

Good oracle tasks:

- architecture tradeoffs,
- plan drift,
- hidden contradictions,
- high-impact direction changes,
- deciding whether to pivot.

Oracle is advisory. The main agent decides what to do with the recommendation.

## Delegation contracts

When launching a subagent, provide a compact contract:

- Goal
- Relevant context or evidence
- Files, paths, plan, diff, or command output
- Success criteria
- Hard constraints
- Validation expectations
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
