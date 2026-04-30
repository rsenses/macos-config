---
description: Final review before commit or PR
---

Use the `reviewer` subagent for this task.

I am about to commit these changes. Perform a final review of the staged diff and tell me whether it is ready to submit.

1. Inspect the current branch and git status.
2. Review the staged files and the staged diff summary.
3. Limit your analysis exclusively to the staged diff and, if included, `CHANGELOG.md`.
4. Check whether the commit is properly scoped.
5. Assess whether `CHANGELOG.md` is missing or incomplete for this change.
6. Estimate the SemVer impact suggested by the change: `patch`, `minor`, or `major`.
7. Point out quick risks before opening a PR.
8. Do not run tests or fixes.
9. Do not commit automatically.

Final output:

- commit scope
- changelog status
- SemVer impact
- staged files
- risks before PR
