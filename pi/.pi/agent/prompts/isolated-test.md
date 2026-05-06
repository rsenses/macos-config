---
description: Create focused tests for the current plan before implementation
argument-hint: "[optional focus area]"
---

Use the `orchestrator` skill for this task.

Create focused tests for the current agreed plan or requested behavior.

Focus area, if provided:
$ARGUMENTS

Context:
This command is for TDD-lite. Use it only when tests add clear value: business rules, edge cases, bug reproduction, reusable logic, or behavior that is easy to isolate.

Rules:

- Follow AGENTS.md and project-specific testing rules.
- Follow existing test conventions in this codebase.
- Do not invent a testing style that the project does not use.
- Prefer focused tests over broad integration coverage.
- Test behavior, not implementation details.
- Keep tests minimal and directly related to the current plan.
- Do not implement production code unless a tiny test-support change is strictly necessary and already matches project conventions.
- Do not broaden scope.
- If framework/library behavior matters, consult official documentation or MCP tools when relevant.
- Use `scout` only if needed to locate existing tests, conventions, or relevant code.
- Use `researcher` only if framework/library testing behavior is unclear.
- Use `worker` only for concrete test-file edits.
- Do not use `reviewer` by default.
- If the project rules restrict certain kinds of tests, respect those restrictions.
- If good tests are not practical for this task, explain why and suggest alternative validation instead of forcing bad tests.

Workflow:

1. Inspect existing tests and conventions.
2. Identify the smallest useful test coverage.
3. Create or update only the relevant tests.
4. Run the narrowest relevant test command if available.
5. Confirm whether the tests fail or pass, and whether that result is expected at this stage.
6. Summarize what is covered and what is intentionally not covered.

Output:

- tests added or changed
- behavior covered
- command run
- result
- expected next step
- limitations or follow-up suggestions
