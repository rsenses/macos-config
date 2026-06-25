# System Rules

Be brief.

- **Discovery**: Prefer `fd` over `find`. Use `find` only if `fd` is missing or for POSIX-specific behavior.

## Changelog Policy

- If `CHANGELOG.md` exists at the project root, every job that produces user-visible changes MUST add or update a SemVer-aligned Keep a Changelog entry before finalizing.
- If `CHANGELOG.md` does not exist, do not create it unless the user or project conventions explicitly ask for one.
- The changelog entry must describe the actual current-job impact; placeholders or unrelated cleanup entries do not satisfy this policy.

## Complexity Triage

Default rule: for any Medium or Serious task, prefer scout/researcher first before editing.

Classify the task before opening context or delegating:

- **Simple**: 1 file/local change, obvious pattern. Solve with minimal inspection.
- **Medium**: Multiple files, contained scope. Targeted search and pattern confirmation required.
- **Serious**: Auth, security, critical data, framework behavior, or risky bugs. Deep investigation.
  **Rules**: If in doubt, start with a quick check. Do not assume; do not over-investigate, allways use subagents

## Loop Control

- If a search, diagnosis, or fix produces no new evidence after two passes, change strategy or stop and ask.
- If the same failure repeats twice, do not keep retrying; summarize the blocker and update the plan.
- If a route, component, file, or decision is already recorded, refer to the existing section or item instead of restating it.
- Prefer delta updates over reprinting inventories or plans.

## Subagents: when to use them

Use subagents when the work benefits from a separate context or parallelization.

- **scout**: map the codebase, locate patterns, compare files, answer "where is this done?"
- **researcher**: check docs, APIs, framework behavior, or external references
- **worker**: isolated implementation or edits in a bounded slice

Good triggers:

- more than one file needs inspection
- you need parallel discovery
- the task mixes exploration + implementation
- the current context is getting crowded

Avoid subagents for:

- a single obvious local edit
- simple one-file fixes
- work you can confirm with one quick check

Rule of thumb: if the task is Medium or Serious, strongly consider delegating discovery to scout/researcher before editing.
