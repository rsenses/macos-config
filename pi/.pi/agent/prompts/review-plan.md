---
description: Review a saved implementation plan manually
argument-hint: "[plan path or name]"
---

Run a **manual-only** review of one saved implementation plan with the `plan-reviewer` subagent.

Plan selection:
- If an argument was supplied, use that exact saved plan path or name: `${ARGUMENTS}`. Locate it if the user gave a filename/name, but do not silently substitute a different plan.
- If no argument was supplied, call `get_current_plan` and use the path it reports. This normally resolves to the current session plan and otherwise the latest saved plan.
- If the selected plan does not exist, stop and report the missing path; do not review a guessed alternative.

Rules:
1. This workflow is activated only because the user invoked `/review-plan` or explicitly asked for a saved-plan review.
2. Dispatch exactly one `plan-reviewer` subagent. Do not ask the architect or planner to perform this review, and do not let the architect invoke `plan-reviewer` merely because a review could be useful.
3. Pass the reviewer a compact contract containing: the exact target path; the goal of challenging the saved plan against the codebase and domain documentation; the fact that the review is read-only; the requirement to use `grill-with-docs`; and the acceptance/output shape from the agent definition.
4. After the reviewer returns, present its verdict, evidence, focused questions, and proposed plan amendments. Do not edit the plan or implementation as part of this prompt.
5. Keep the review bounded to the selected plan and relevant evidence. Do not create a second plan.

**Reviewer task contract**:

- **Goal**: Adversarially review the saved plan at the exact selected path for coherence, domain terminology, codebase fit, scope, risks, acceptance, and validation.
- **Known**: The plan is the canonical saved artifact; use the `grill-with-docs` skill as the review lens; this is read-only and manual-only.
- **Evidence**: Read the complete target plan, then inspect only relevant repository files and documentation. Cite exact paths/lines.
- **Acceptance**: Return the required `plan-reviewer` shape with a verdict, severity-ranked findings, one-at-a-time questions with recommended answers, and concrete plan amendments without editing files.
- **Checks**: Confirm the target exists, read the full plan, verify claims against relevant code/docs, and report checks actually performed.
- **Stop**: Missing target, material ambiguity, or insufficient repository evidence; return `blocked` with the exact unresolved item.
