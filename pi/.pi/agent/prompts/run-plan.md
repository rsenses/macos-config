---
description: Execute the approved/current plan
argument-hint: "<prompt>"
---

Execute the current plan for: $ARGUMENTS

Load `ops` and `dev`. Load `architect` only for a material design question; do not redesign an approved plan merely to execute it.

1. Resolve with `get_current_plan` and read the Markdown contract, Current Step, next authorized task, acceptance, and validation. Before execution, contrast the current plan with relevant later user decisions available in context; if there is a material contradiction, stop and ask for clarification; otherwise continue without additional verification. Apply ops' selection/resumption rules; missing, ambiguous, stale-worktree, incomplete, or unresolved plans need an actionable blocker, not a guessed alternative.
2. Explain the scope, purpose, material risks, stop rules, and validation. Obtain the separate implementation approval through the question tool/UI once; no worker or implementation before confirmation. Cancellation preserves the plan and ends the attempt.
3. After approval, set the plan to `in-progress` and record the current task before work. Follow dependencies and acceptance one bounded slice at a time. Follow ops' task-by-task handoff: each worker stops after one assigned task; the coordinator reviews its diff and verifies acceptance before assigning the next dependent task. Parallelize only independent slices expressly permitted by the plan, with no overlapping writes or checks requiring a stable tree.
4. Apply ops' worker brief, write-isolation, local acceptance, and single-writer progress contracts. Include applicable `dev` criteria in Known using ops' selective skill-handoff rule. Check off work only after verifying acceptance; child process success is insufficient. Report useful deltas at meaningful milestones, not repeated inventories or raw child reports.
5. Preserve resumable evidence on partial/blocked/cancelled/timed-out outcomes. On resume, skip only work whose acceptance remains valid; recheck stale evidence. Stop for material ambiguity, unplanned scope, conflicting behavior, or repeated attempts without new evidence.
6. Apply the changelog policy on the final tree. Report the checks that ran (commands/results) and those that did not, the status, unresolved work, and the next action. Full validation uses project-specific commands only on explicit user request; user-confirmed checks are evidence, not agent executions or authorization to rerun them. No commits, remote changes, or automatic plan-reviewer calls.
