---
description: Run CodeRabbit CLI review for agent-readable feedback
---

Run a CodeRabbit CLI review for the current working tree diff.

Rules:

- Do not modify files.
- Do not apply suggestions automatically.
- Use CodeRabbit only as an external reviewer.
- Do not search for how to run CodeRabbit.
- Use the predefined command below.
- Summarize only actionable findings.
- Separate blocking issues from optional suggestions.
- Ignore purely stylistic suggestions that would be handled by `composer fix`.

Execution:

- Run:
  `cr review --agent --type uncommitted`

- If the command fails due to missing installation or authentication:
  - explain the issue
  - do not attempt alternative commands.

Output:

- command executed
- blocking findings
- non-blocking findings
- suggestions to ignore
- recommended next action
