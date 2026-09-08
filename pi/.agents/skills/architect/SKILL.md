---
name: architect
description: Specification design, behavior contracts, and risk-aware task decomposition.
---

# Architect: Design and Planning

## 0. Intent Translation

For an ambiguous request, translate it into a canonical brief:

- **Objective**, **Non-goals**, **Constraints**, **Assumptions**, **Success Criteria**, and **Open questions**.
- Ask one focused clarification only when different interpretations or material safety/risk would change the work.
- For a clear, bounded request, do not add a discovery or documentation phase merely because it is multi-file.

## 1. Specifications and Gates

Make behavior and boundaries testable before editing when ambiguity, architecture, security, data integrity, or production risk is material. For a clear low-risk change, keep specification lightweight.

Use a compact contract: **Goal**, **Known**, **Evidence**, **Acceptance**, **Checks**, and **Stop**. Preserve user decisions, security invariants, unrelated existing changes, and applicable changelog policy.

## 2. Planning and Decomposition

Decompose only as much as improves execution. Use the planner subagent only when architecture/acceptance is genuinely ambiguous, risk is high, or an independent planning/investigation slice has positive net value. Do not delegate solely for file count or “non-trivial” labels. The principal owns the final plan, scope, and acceptance; planner and worker do not launch nested subagents.

Prefer one ordered checklist with exact files/symbols, dependencies, acceptance, and checks. Split tasks when independence or verification benefits; do not manufacture parallelism or duplicate plans. Define checkpoints around meaningful risk boundaries.

## 3. Execution Coordination

Give a child a single explicit slice and the compact contract. Normally use zero or one child; use at most two only for genuinely independent, non-overlapping work. Review evidence and status before integrating. A child that lacks a material prerequisite returns `blocked` rather than expanding scope.

## 4. Changelog Requirement

If `CHANGELOG.md` exists at the project root and the job is user-visible, include a SemVer-aligned Keep a Changelog update in the work. Do not create it when absent unless explicitly requested.

## 5. Documentation Economy

Read the relevant versioned contract or sections, not a generic transitively linked tour. Share exact evidence and reuse it; do not make principal, planner, and worker restate the same plan or documentation.

## 6. Final Gate

Before completion, verify acceptance and specified checks, report unresolved risk honestly, and summarize the delta once. Human confirmation is reserved for the clarification and critical-configuration gates above; it is not a routine planning step.
