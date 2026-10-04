---
description: Revise the active plan from feedback or new evidence
argument-hint: "<reason>"
---

Use `ops`; load `architect` when the feedback requires a design decision.

Update the active plan because: "$ARGUMENTS"

1. This changes the plan document, not implementation. Resolve the active selection with `get_current_plan` and read the complete target; do not choose another file by date or name guesses. Report an absent or blocked selection.
2. Classify the revision. A recorded check, progress update, or wording correction without a design change can be applied directly. Material changes to architecture, behavior, scope, or dependencies require a planner proposal for the affected sections, using the same model-selection and approval policy as `/plan`.
3. Prepare the new evidence, user decisions, and affected contract without pre-solving the design. Preserve the single launcher approval; cancellation ends the attempt, with no fallback or changes on its behalf.
4. Integrate the authorized correction or planner proposal into the same file, preserving unchanged task IDs, inventories, decisions, and relevant acceptance evidence. Keep partial/blocked proposals unresolved; do not fill gaps by guessing. A design change does not authorize starting its implementation.
5. Read back the complete updated document and verify internal consistency, dependencies, Current Step, and acceptance. Report the changed behavior and unresolved decisions in plain language, with the path as a reference.
