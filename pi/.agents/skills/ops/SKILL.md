---
name: ops
description: Memory management (.ai/), context engineering, selective subagent coordination, and implementation validation.
---

# Ops: System Control and Memory

## 1. Memory Management (.ai/)

Use project-relative paths. The restriction to `.ai/` applies to memory artifacts (`MEMORY.md`, `TASKS.md`, plans, daily notes), not authorized implementation files.

### Persistence and selection

Save a plan when durable decisions, related phases, resumption, or a handoff need it. Explaining a proposal, file count, and multiple steps alone do not require persistence. Outside `/plan`, do not routinely create a plan or ask whether to create one. `/plan` explicitly requests persistence and retains its mandatory planner and approval gates.

- Reuse the active selection. Showing, serving, testing, or reviewing completed work continues its plan. Handle one-off follow-ups directly; append a task if tracking is useful. A new plan needs an independent goal or material scope change; compare the current goal/artifacts before `newPlan=true`, asking only if the distinction is unclear.
- `select_session_plan` is for explicit existing-file adoption/switch. It and `create_session_plan(newPlan=true)` obtain their own UI confirmation; do not ask again. Cancellation preserves the previous selection and ends the attempt. Selection never authorizes implementation.
- Resolve identity with `get_current_plan`, never newest-file heuristics. Selection follows the full active branch, including compacted metadata, not another branch. A blocked or missing selection is never silently recreated.
- At start/resume, read the selected Markdown contract, Current Step, next authorized task, acceptance, and validation. After compaction, reread only if retained context is insufficient; within a task reuse evidence. Recheck at task changes or material discrepancies, not before every call. `summarize_worktree` is the compact repo view.

### Canonical plan

Use the existing `## TL;DR`, `## Current Step`, and `## Tasks` structure with stable top-level `Tn` IDs; do not introduce another template or migrate old plans just to shorten them.

Current Step has three lines:

- `- Current: T1` (an existing task ID or `none`)
- `- Next: T2` (an existing task ID or `none`)
- `- Blockers: none` (or concise evidence)

An explicit nonexistent ID is an inconsistency, not permission to substitute a task. Keep old free-form steps readable.

Capture objective, constraints, behavior, material decisions/reasons, implemented-versus-verified work, pending checks, blockers, and next action. Tasks are verifiable outcomes, not a log of tool calls. Include exact files, symbols, dependencies, acceptance, and checks only when execution or verification needs them. Record checks actually run; refer to existing inventories instead of copying them.

Before a planner returns, record only the brief and evidence. The planner is read-only; it supplies the design, then the coordinator saves the complete proposal and reads it back in full. Preserve partial/blocked results and unresolved questions rather than designing missing pieces yourself. Persistence or read-back failure is blocked, not completed planning.

### Progress and handoff

When a later user decision supersedes the design, consolidate the current TL;DR, task contract, acceptance, Current Step, and blockers. Preserve earlier evidence as explicitly historical; do not leave contradictory instructions active. Record user-confirmed checks as user-confirmed, with their scope and timing, not as checks the agent ran.

The coordinator alone writes plan progress after verifying acceptance. Check only accepted tasks; a child's success is not acceptance. Update Current Step, concise evidence, checks/results, and blockers. Routine progress updates do not require a planner.

Give a worker its plan path/task ID as references plus the bounded brief below, writable files, established decisions, permitted checks, and stop condition. Do not pass the full plan or conversation by default. Integrate its result once after local verification.

Markdown is the sole editable source of plan content. The extension resolves selection and serves explicit reads; lifecycle events do not synchronize document contents into prompts. Do not call unavailable memory tools or create a second daily log by default. Put only stable lessons in `MEMORY.md`; keep `TASKS.md` focused on pending work and link complex plans.

## 2. Context Engineering

Load relevant project rules, source ranges, and versioned contracts; reuse evidence. Minimize total tokens needed for a verified outcome, not merely one request. Bound/filter tool output before it enters context; recover only needed ranges. Keep changing state out of reusable system/tool prefixes and append explicit results instead.

When a clear contract conflicts with code, investigate and fix within scope. If competing rules make intended behavior undecidable, report the exact conflict and ask before changing it.

## 3. Selective Delegation

The principal owns scope, decisions, integration, and final validation. Delegate only when specialization, isolation, or independently verifiable work outweighs briefing and integration overhead; separability or file count alone is insufficient.

- Normally use zero or one child, at most two genuinely independent, non-overlapping tasks. Do not manufacture work to fill a quota.
- Handle direct questions, trivial lookups, and indivisible edits locally without routinely explaining why no child was used.
- `/plan` requires a planner design; preparation gathers evidence without pre-solving it. Elsewhere use a planner for material alternatives, not routine status updates.
- Children cannot delegate. Missing material prerequisites return `blocked` with the exact question. Use direct tools for orientation, deterministic operations, and final validation.
- `plan-reviewer` is manual-only: invoke it only when explicitly requested for a saved plan or through `/review-plan`, never automatically from architect, planner, `/plan`, or `/run-plan`.

### Brief and output contracts

Every brief uses these headings:

- **Goal**: bounded outcome/scope and write permissions.
- **Known**: decisions, constraints, invariants, and existing changes to preserve.
- **Evidence**: checked paths/ranges/URLs or excerpts, plus the remaining unknown.
- **Acceptance**: observable result, including security and applicable changelog requirements.
- **Checks**: concrete permitted checks; never invent provider calls.
- **Stop**: ambiguity, scope conflict, missing evidence, or repeated failure without new evidence.

Pass established evidence and the remaining question, not a transcript or a request to rediscover facts. Request concise evidence, but preserve the complete actionable design when planning. Keep one canonical plan; integrate results once instead of copying reports across artifacts and chat.

Child output starts with **Status** (`complete`, `partial`, `blocked`, `failed`, `cancelled`, `timed_out`), then its role's findings/changes, evidence, checks, and unresolved items. Workers return **Status / Changes / Evidence / Checks / Unresolved**. Name their validation policy (`no-tests`, `targeted-check`, `add-test`, `test-first`, `defer-validation`) and the concrete command or reason.

### Skill references for children

Children run with `--no-skills`: neither skill discovery nor the principal's loaded skills/conversation are inherited. In **Evidence**, identify each applicable skill by name and readable path, and require explicit reading before work. For applicable PHP/Laravel changes, workers must read `laravel-simplicity` (`~/.pi/agent/skills/laravel-simplicity/SKILL.md`, or its checked repository path) and relevant references; pass domain/consumer evidence rather than assuming inherited context. Workers never write plan progress; only the coordinator accepts work and updates it.

### Integrated code review

Use `code-reviewer` after a relevant implementation, including work done directly by the principal, not only delegated slices. Relevant means changed behavior/integration, security/data integrity, or non-trivial logic/abstractions. Questions, read-only work and trivial non-behavioral edits do not require it. Explicit user prohibitions on delegation/provider calls take precedence: report review as not run, never label self-inspection an independent review. No plan is required: without one, review against the user's assignment.

Sequence: implementation and targeted checks → independent review of the integrated change → coordinator verifies findings → accepted corrections → final validation when authorized → user report. Targeted tests remain allowed during development. Freeze the reviewed portion first: no workers or coordinator writing it concurrently.

Use the standard brief headings above, supplying:

- **Goal/Known**: the original user request and relevant clarifications; approved decisions clearly separated from agent assumptions. Later user clarifications can legitimately supersede the plan.
- **Evidence**: current plan/contract when one exists, the actual relevant diff, and paths/ranges for related producers, consumers and domain rules. The implementer's summary is not the sole evidence; the reviewer must compare it with code.
- The coordinator prepares Git evidence: inspect status, staged and unstaged diffs and pertinent new/untracked files. Include new-file contents/diffs and relevant uncommitted work, excluding unrelated/pre-existing work. Identify the baseline, included paths/hunks and preserved changes so attribution is explicit; if attribution is unclear, resolve it before review. Pass excerpts or a readable artifact with enough context, not only a diffstat. The reviewer needs no shell.
- **Acceptance/Checks/Stop**: restrictions, observable acceptance, checks already performed with results, unrun checks, applicable skill paths (including this contract), and exact missing evidence that should block a conclusion. Do not pass the whole conversation by default.

Require this review order:

1. **Fidelity**: omitted requirements, unsolicited changes and lost constraints against the current assignment/approved decisions, not blind adherence to a superseded plan.
2. **Behavior and integration**: trace relevant producers and consumers, permissions, persistence and observable effects. Apply `dev`'s Consumer acceptance criteria for persisted/generated outputs and UI; supply its readable path and require that section to be read when relevant. Source inspection alone cannot establish that a UI works; mark rendering/runtime checks not performed as unverified.
3. **Simplicity**: flag unnecessary abstractions, branches or mechanisms only with evidence that they add no required benefit. For PHP/Laravel, require explicit reading of `laravel-simplicity` and its relevant references; reuse its contract/consumer reasoning rather than copying the skill.

Reviewer output: **Status / Findings / Evidence / Checks / Unresolved**. Each finding identifies `confirmed defect`, `open question`, or `optional suggestion`, plus severity, location, evidence, impact and the minimal correction (or precise missing fact for a question). No minimum findings; `none` is valid. No style-only recommendations, speculative complexity claims, or preferred alternative architectures. Read-only review neither implements nor approves more work or changes scope.

The coordinator checks findings against code, request and approved decisions; accepts or rejects recommendations with evidence. Ask the user about ambiguous decisions that change behavior. Apply only accepted, authorized corrections. Use one initial review and, for substantive corrections, one focused `code-reviewer` follow-up on the corrected portion; unresolved issues become explicit blockers/questions, not indefinite review/rewrite loops. If a later fixer changes behavior, review that affected portion; formatting alone does not restart review.

Keep findings in the child's result (recover its full output artifact if clipped). Do not mandate a separate review document. In an existing plan record only material accepted/rejected decisions, corrections, unresolved risks and review/check evidence needed for continuity. Child completion is not acceptance or application readiness.

### Approval boundaries

The launcher approves planner model/thinking once, showing `profileReason`; the user may choose another available profile. Selection tools confirm adoption or `newPlan=true`; implementation still needs separate user authorization. Never duplicate UI questions. Cancellation ends the attempt without retry/fallback; report unavailable profiles, models, or thinking instead of silently changing them. Keep principal model/provider/thinking/settings unchanged unless explicitly requested.

## 4. Validation reporting

Full project validation (for documented Laravel/PHP projects: `composer fix`, then `composer test`, from the project root) runs only when the user explicitly requests it or runs it themselves. The agent does not run it or require it as a gate before other work.

Any implementation status report states which checks ran (command, exit result, notable output) and which did not. Targeted checks, dry runs, and child success are reported as targeted, never as full validation. Do not say tests pass or that work is ready to ship unless the relevant checks ran and succeeded; name the unverified remainder instead.

Planning, read-only review, and worker slices use their scoped checks. Changelog entries follow APPEND_SYSTEM's Changelog Policy.

## 5. Direct Questions

Answer conceptual questions directly. Inspect files or delegate only when repository-specific evidence is needed, using the smallest useful lookup.

## 6. Clarification and Risk Gate

Ask one focused question for material ambiguity, preference, or safety/data/production risk. Otherwise perform authorized bounded work without routine confirmation. Preserve APPEND_SYSTEM's specific workflow gates once each; do not repeat launcher, selection, or implementation approvals.

## 7. Critical Configuration Safety

Before editing critical local/system configuration, create a timestamped backup and explain the intended change. This includes `.env`, SSH, credentials, deployment/production, shell/profile, and database/client configuration. Explicit approval is required.

## 8. Loop Control

After two attempts without new evidence, change strategy or stop. Do not repeat the same failure twice without new evidence or restate a known route, decision, or inventory.
