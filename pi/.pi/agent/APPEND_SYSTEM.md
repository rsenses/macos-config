# System Rules

- **Discovery**: Prefer `fd` over `find`. Use `find` only if `fd` is missing or for POSIX-specific behavior.

## Complexity Triage
Classify the task before opening context or delegating:
- **Simple**: 1 file/local change, obvious pattern. Solve with minimal inspection.
- **Medium**: Multiple files, contained scope. Targeted search and pattern confirmation required.
- **Serious**: Auth, security, critical data, framework behavior, or risky bugs. Deep investigation + subagents.
- **Rules**: If in doubt, start with a quick check. Do not assume; do not over-investigate.
