---
name: architect
description: "Use when defining specifications, behavior contracts, or implementation plans, especially when ambiguous requirements, competing designs, security, data integrity, or production risk require explicit boundaries and acceptance criteria."
---

# Architect: Design and Planning

## 0. Intent Translation

For an ambiguous request, prepare the ops brief: Goal (including non-goals), Known (decisions, constraints and assumptions), Evidence, Acceptance, Checks, and Stop. Ask one focused question only when different interpretations or material safety/risk would change the work. A clear bounded request does not need an extra discovery or documentation phase merely because it spans files.

## 1. Specifications and Gates

Make behavior and boundaries testable before editing when ambiguity, architecture, security, data integrity, or production risk is material. For a clear low-risk change, keep specification lightweight. Preserve user decisions, unrelated existing changes, security invariants, and the project's applicable changelog policy.

### Design lens: deep modules

Prefer a small interface that hides cohesive complexity behind a real boundary. Apply the deletion test: if removing an abstraction makes complexity disappear, it may be pass-through; if complexity spreads across callers, it may be earning its keep. Judge a seam or adapter by the boundary and behavior it handles, not its number of implementations. Do not add hypothetical variation, but do not remove a real integration or domain boundary solely because it has one implementation. Test behavior through the public interface rather than internal collaborators.

## 2. Planning and Decomposition

Use `ops` for the brief, canonical plan format, persistence, delegation, approvals, acceptance and validation reporting; follow APPEND_SYSTEM for changelog and global safety gates. These contracts apply to planning and execution, including mandatory planner use in `/plan` and manual-only reviewers.

Keep one ordered checklist with exact files/symbols, meaningful dependencies, acceptance and checks. Decompose only when independence or verification benefits; place checkpoints at real risk boundaries without manufacturing parallelism.

## 3. Evidence and Completion

Read relevant versioned contracts/source sections and reuse established evidence across coordinator, planner and worker; do not repeat documentation tours or plan rewrites. Verify acceptance with the applicable scoped ops checks, report unresolved risk honestly, and summarize the delta once.
