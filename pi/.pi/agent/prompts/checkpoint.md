---
description: Review whether current changes are properly grouped for commit
---

Use the `orchestrator` skill for this task.
Use the `ship` skill for commit grouping principles.
Use the `reviewer` subagent for non-trivial grouping reviews.

I want to review whether my current changes are properly grouped before committing. Do not update memory files during this read-only grouping review.

1. Inspect the current branch, git status, staged files, and unstaged files.
2. Clearly separate reasoning between staged and unstaged changes.
3. Determine whether there is a single coherent intention or multiple mixed concerns.
4. Propose clean commit groupings and which files belong to each.
5. Identify which files should be removed from the current commit.
6. Suggest 2–3 precise commit messages.
   Base them on the user's stated outcome and current session plan Goal / Expected Changes when available, not on the most recent low-level implementation detail.

Be strict about logical separation of changes. Focus on clarity, minimal scope per commit, and maintainable history. Do not modify files or memory.
