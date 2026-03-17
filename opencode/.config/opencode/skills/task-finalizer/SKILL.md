---
name: task-finalizer
description: Use when closing a task to run project fix/test flows, verify changelog, and prepare a safe Conventional Commit.
---

When finishing work:

- run the project's standard fix command,
- then run the project's standard test command,
- inspect whether fix changed files,
- verify there is an appropriate changelog entry in `changelogs/`,
- do not auto-commit,
- propose a Conventional Commit message in the format `type(scope): summary`.

Prioritize:

1. formatting and autofixable issues
2. quality and test failures
3. changelog completeness
4. commit scope clarity

Final output:

- checks run
- failures remaining
- changelog status
- files touched
- Conventional Commit suggestion
