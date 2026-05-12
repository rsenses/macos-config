---
description: Review branch and repository state before starting a task
---

Use the `orchestrator` skill for this task.
Use the `planner` subagent for this task only if it adds value beyond direct git inspection.

I am starting this task. Use loaded project memory as context, but do not create or update memory files during this preflight check.

1. Inspect the current branch.
2. Review the git status.
3. Show recent commits.
4. Analyze whether the current branch is appropriate for this work.
5. Detect whether the working tree is clean or contains previous changes.
6. Identify if there is any mix of intentions.
7. Recommend a proper branch name for this task.
8. Provide a short implementation plan with a lightweight Spec / Contract only when requirements are already clear enough.

If I am on a protected branch or the working tree is dirty with unrelated changes, clearly state it at the beginning.
