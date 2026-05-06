---
description: Final review before commit or PR
---

Use the `orchestrator` skill for this task.
Use the `reviewer` subagent for this task.

I am about to commit these changes. Perform a final review of the staged diff and tell me whether it is ready to submit.

Rules:

- Review only the staged changes.
- Do not inspect or comment on unstaged changes unless they affect whether the staged commit is safe.
- Limit your analysis to:
  - current branch
  - git status
  - staged files
  - staged diff
  - `CHANGELOG.md`, if staged or relevant
- Do not run tests.
- Do not run fixers.
- Do not modify files.
- Do not commit automatically.

Review checklist:

1. Inspect the current branch and git status.
2. Review the staged files and staged diff summary.
3. Check whether the commit is properly scoped.
4. Check whether staged changes include unrelated work.
5. Assess whether `CHANGELOG.md` is missing or incomplete for this change.
6. Estimate the SemVer impact suggested by the change: `patch`, `minor`, or `major`.
7. Point out quick risks before opening a PR.

Final output:

- commit scope
- changelog status
- SemVer impact
- staged files
- blocking risks
- non-blocking risks
- final verdict: `ready to submit` or `not ready to submit`
