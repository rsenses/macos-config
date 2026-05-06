---
description: Run fix and test, then leave the task ready for final review
---

Use the `orchestrator` skill for this task.
Use the `worker` subagent only for concrete file edits.

I am ready to close this task. Run the project’s final validation flow and leave everything ready for final review.

Context:

- The implementation has already been manually reviewed by me.
- Do not perform a broad review unless tests fail, the fix changes relevant logic, or you detect a clear risk.

Validation flow:

1. Read AGENTS.md or project guidance to identify the project’s standard fix/format command and test command.
2. If no project-specific commands are defined, use these defaults:
   - fix command: `composer fix`
   - test command: `composer test`
3. Run the project’s standard fix/format command.
4. Check whether it modified any files and summarize those changes.
5. Run the project’s standard test command.
6. Summarize any errors or failures.
7. Prioritize any issue that could break CI/CD or block deployment.
8. Check whether `CHANGELOG.md` needs to be updated based on the changes.
9. If a user-visible changelog entry is missing and the project convention requires one, add it using Keep a Changelog format aligned with SemVer.
10. Do not commit automatically.
11. Propose the most appropriate Conventional Commit type and scope, and recommend a final commit message in the format `type(scope): summary`.

Agent escalation rules:

- Do not use reviewer agents by default.
- The main agent should handle orchestration, changelog checks, and commit message suggestions.
- Escalate to the `reviewer` subagent only if:
  - the fix/format command introduces non-trivial logic changes,
  - the readiness-to-ship verdict is ambiguous after reading the diff and command outputs,
  - the changelog impact is ambiguous, user-facing, and cannot be determined from the diff and plan alone.
- If this task produced a durable project lesson or decision, mention that it may be worth saving to memory. Do not update long-term memory unless explicitly appropriate.

Rules:

- Do not introduce unrelated refactors.
- Do not expand the task scope.
- Do not update `CHANGELOG.md` for purely internal changes unless the project convention requires it.

Final output:

- checks executed
- files modified by fix/format
- test status
- final working tree status
- changelog status
- blocking issues
- non-blocking issues
- final verdict: `ready to ship` or `not ready to ship`
- risks before final review
- Conventional Commit suggestion
