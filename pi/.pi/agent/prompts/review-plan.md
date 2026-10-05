---
description: Review a saved implementation plan manually
argument-hint: "[plan path or name]"
---

Perform a manual-only, read-only review with exactly one `plan-reviewer` subagent. Load `ops` for the delegation contract.

Resolve the target:
- With an argument, use the exact path/name: $ARGUMENTS. Locate a supplied filename without substituting another plan.
- Otherwise use only the active selection from `get_current_plan`. An absent, ambiguous, blocked, or missing target requires an explicit selection or an actionable blocker; never choose the newest file.

Send the canonical ops brief:
- **Goal**: Challenge the exact saved plan against code and domain documentation: terminology, behavior, scope, risks, acceptance, and validation.
- **Known**: Read-only, manual-only; use `grill-with-docs` as the review lens.
- **Evidence**: Read the complete target, then only relevant code/docs; cite exact paths/lines.
- **Acceptance**: The agent's required verdict and severity-ranked findings, focused one-at-a-time questions with recommended answers, and concrete proposed amendments.
- **Checks**: Verify existence, complete reading, and source-backed claims; report actual checks.
- **Stop**: Missing target, material ambiguity, or insufficient evidence; return `blocked` with the exact unresolved item.

Present the verdict, evidence, questions, and amendments. Do not edit the plan or implementation, create another plan, or replace this reviewer with architect/planner.
