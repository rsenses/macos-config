---
description: Execute the approved/current plan
argument-hint: "<prompt>"
---

Use `ops` and `dev`. Load `architect` only if a material design question arises; do not redesign the approved plan merely to execute it.

**Goal**: Execute the current plan for: "$ARGUMENTS", as a coordinated, recoverable execution gated by durable task state in the plan file.

**Rules**:

1. Validate the active plan before execution. Use `get_current_plan` and read the full body when the bounded view is insufficient. Refuse a missing, ambiguous, stale-worktree, incomplete, or unresolved plan with an actionable blocker, not a guessed alternative. Never select by modification time.
2. Present a concise execution preview following APPEND_SYSTEM: what will change and why, scope, material risks, stop rules, and validation. Then obtain the existing explicit implementation confirmation through the question tool/UI, once. No subagent or implementation before confirmation. Cancellation preserves the plan and ends the attempt.
3. After approval, set the plan to `in-progress`. Follow the ops Current/Next/Blockers and Tn format; mark the current task in progress before work. Respect dependencies and recorded acceptance. Execute sequentially by default; parallelize only genuinely independent slices explicitly permitted by the plan, never overlapping writes or checks requiring a stable tree.
4. Reuse existing inventories and evidence by reference. Report only new, changed, or missing information.
5. Execute one bounded slice at a time. Use workers when the ops delegation criteria are met, with their exact Goal/Known/Evidence/Acceptance/Checks/Stop contract and write boundaries. Resolve indivisible surgical edits directly; do not manufacture a child for every checkbox.
6. Workers never delegate. Missing material evidence returns to the coordinator as a blocker. Inspect their Status/Changes/Evidence/Checks/Unresolved and run credible local acceptance checks yourself. A successful process is not task acceptance; targeted checks never replace the final full-project gate.
7. After each task, update the same plan with acceptance status, changed paths, commands/results, Current Step, and unresolved evidence. Check off only accepted work. At meaningful milestones explain outcomes and next work in plain language instead of echoing worker reports.
8. Persist evidence on partial, blocked, timed-out, or cancelled outcomes rather than restarting. Stop on material ambiguity, unplanned scope, or a genuine conflict about intended behavior. Two attempts without new evidence require a different strategy or an explicit blocker.
9. On resume, read task and validation records and skip only work whose acceptance remains valid. Re-verify stale evidence, not every already-accepted step. Routine progress updates do not require replanning; escalate material design changes explicitly.
10. Before reporting overall implementation completion, satisfy ops section 4 on the final tree, including required changelog edits, complete fix/format/lint, and complete tests. Record final commands/results and status. If the gate is incomplete, retain partial/blocked and report `not ready to ship` with the concrete reason. Finish with a human-facing delta, validation evidence, unresolved work, and the next resumable action. No commits, remote changes, or automatic plan-reviewer calls.
