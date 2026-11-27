---
name: ops
description: "Use before implementing, delegating, or reporting readiness for shared safety, approval, validation and delegation policies. For plans and resumption, routes to the shared memory contract and planning/execution workflows."
---

# Ops: Shared Operational Policies

## Workflow routing

Direct work uses the shared policies below; it does not require a plan or the planning/execution workflows.

- For `.ai/` memory, plan selection, format, revisions or resumption, read [the shared plan-memory contract](references/plan-memory.md).
- `/plan` owns plan creation, mandatory planner delegation, proposal persistence/read-back and presentation. `/fix-plan` owns revisions, using the shared memory contract.
- When executing an existing plan, read `~/.pi/agent/prompts/run-plan.md` for coordinator continuity, task acceptance and stop conditions, even when execution was requested directly. Its extra implementation-approval UI applies only to an explicit `/run-plan` invocation; direct work still needs user authorization for its scope.

## Context Engineering

Load relevant project rules, source ranges, and versioned contracts. Keep changing state out of reusable system/tool prefixes; append explicit results instead. APPEND_SYSTEM governs evidence reuse and bounded tool output.

When a clear contract conflicts with code, investigate and fix within scope. If competing rules leave intended behavior undecidable, use the clarification gate below before changing it.

## Selective Delegation

The principal owns scope, decisions, integration and final validation. Delegate only when specialization, isolation or independently verifiable work outweighs briefing/integration overhead—not mere separability or file count.

- Normally use zero or one child, at most two genuinely independent, non-overlapping tasks. Do not manufacture work to fill a quota.
- Handle direct questions, trivial lookups, and indivisible edits locally without routinely explaining why no child was used.
- Outside `/plan`, use a planner for material alternatives, not routine status updates; `/plan` owns its mandatory planning flow.
- Children cannot delegate. Missing material prerequisites return `blocked` with the exact question. Use direct tools for orientation, deterministic operations, and final validation.
- `plan-reviewer` is manual-only: invoke it only when explicitly requested for a saved plan or through `/review-plan`, never automatically from architect, planner, `/plan`, or `/run-plan`.
- `code-reviewer` is manual-only: invoke it through `subagent` only when the user explicitly requests that agent to review an existing implementation, including via `/code-review`. Outside that user-invoked workflow, it is not a post-worker, pre-test, `/run-plan`, planning, acceptance, or task-closing stage. Supply the original request, clarifications, decisions, current contract/plan if any, scoped diff, and readable project/skill references in the existing brief. Its recommendations do not authorize fixes or change the current validation policy.

Before delegating or producing a structured clarification brief, read [the brief and output contracts](references/brief.md). Before assessing review findings, read [the findings contract](references/review-findings.md); it adds no review stage or authorization.

### Approval boundaries

The launcher approves planner model/thinking once, showing `profileReason`; the user may choose another available profile. Selection tools confirm adoption or `newPlan=true`; implementation still needs separate user authorization. Never duplicate UI questions. Cancellation ends the attempt without retry/fallback; report unavailable profiles, models, or thinking instead of silently changing them. Keep principal model/provider/thinking/settings unchanged unless explicitly requested.

## Validation reporting

Run full project validation (fix/format/lint, then tests) only on explicit user request, using the project's documented commands. A user's own run may be recorded as user-confirmed evidence, with scope and timing, never as an agent execution or authorization to rerun it. Never require the suite as a gate before other work except in the explicitly invoked `/code-review` workflow.

Any implementation status report states which checks ran (command, exit result, notable output) and which did not. Targeted checks, dry runs, and child success are reported as targeted, never as full validation. Do not say tests pass or that work is ready to ship unless the relevant checks ran and succeeded; name the unverified remainder instead.

For an authorized publication or deployment, use the project's existing procedure; keep concrete commands and provider-specific checks in project documentation, not this skill. Before publishing, confirm the target account/service/environment, check relevant effective configuration against intended exposure/access, and identify permitted checks and post-publication verification for the affected workflow. After publishing, record the deployed version, actual verification and any missing evidence. A successful build or deployment is not proof that the workflow works. If access or authorization prevents verification, report the publication as unverified for that scope, not as accepted delivery. These checks do not authorize publication, real-provider calls or full validation; retain existing approval boundaries.

`/code-review` explicitly authorizes full validation and bounded corrections for that invocation only; its prompt owns the required checks and sequence. This does not enable automatic full validation or review during ordinary development.

Planning, standalone read-only review, and worker slices use their scoped checks; the `/code-review` principal owns its required full validation.

## Clarification and Risk Gate

Answer conceptual questions directly; gather repository-specific evidence only when needed. For material ambiguity, explain the outcome, invariants and open decision, distinguishing decisions, verified facts and assumptions. Ask one focused question when intent, preference or safety/data/production risk requires it; otherwise execute authorized bounded work without routine confirmation or restating clear requests. Apply approval gates once.

`/sharpen` reformulates a request into the shared brief; `/grill-me` supports interactive clarification. Do not chain them or `/plan` automatically. Deepening a brief does not expand scope: keep unrequested improvements optional. Direct work needs none of these commands as a prerequisite.

## Critical Configuration Safety

Before editing critical local/system configuration, create a timestamped backup and explain the intended change. This includes `.env`, SSH, credentials, deployment/production, shell/profile, and database/client configuration. Explicit approval is required.

## Loop Control

After two attempts without new evidence, change strategy or stop. Do not repeat the same failure twice without new evidence or restate a known route, decision, or inventory.
