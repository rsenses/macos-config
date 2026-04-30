---
description: Run fix and test, then leave the task ready for final review
---

Use the `worker` subagent for this task.

I am ready to close this task. Run the project’s final validation flow and leave everything ready for final review.

Context:

- The implementation has already been manually reviewed by me.
- Do not perform a broad review unless tests fail, the fix changes relevant logic, or you detect a clear risk.

1. Run the project’s standard fix command: `composer fix`.
2. Check whether it modified any files and summarize those changes.
3. Run the project’s standard test command: `composer test`.
4. Summarize any errors or failures.
5. Prioritize any issue that could break CI/CD or block deployment.
6. Check whether `CHANGELOG.md` needs to be updated based on the changes.
7. If a user-visible changelog entry is missing and the project convention requires one, add it using Keep a Changelog format aligned with SemVer.
8. Do not commit automatically.
9. Propose the most appropriate Conventional Commit type and scope, and recommend a final commit message in the format `type(scope): summary`.

Agent escalation rules:

- Do not use reviewer agents by default.
- Escalate to the `reviewer` subagent only if:
  - `composer fix` introduces non-trivial changes,
  - the changelog requires interpreting user-facing impact,
  - there is ambiguity about whether the task is ready to ship.
- Escalate to the `debugger` subagent only if:
  - `composer test` fails,
  - there is a CI/CD or deployment risk,
  - you detect a contradiction with the implemented task.

Rules:

- Do not introduce unrelated refactors.
- Do not expand the task scope.

Final output:

- checks executed
- files modified by fix
- test status
- final working tree status
- changelog status
- blocking issues
- non-blocking issues
- final verdict: `ready to ship` or `not ready to ship`
- risks before final review
- Conventional Commit suggestion
