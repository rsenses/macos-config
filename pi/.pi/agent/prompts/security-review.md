---
description: Perform a focused security review without modifying files
argument-hint: "<scope>"
---

Use the `dev` and `ops` skills.

Goal:
Perform a focused security review for the requested scope.

Scope:
$ARGUMENTS

Rules:

1. Do not modify files.
2. Do not run broad scans unless needed.
3. Use `scout` to locate relevant code paths.
4. Use `researcher` only for framework/library security behavior when needed.
5. Prefer project-specific evidence over generic checklists.
6. Keep findings concrete and actionable.
7. Do not report speculative issues as confirmed vulnerabilities.
8. If the scope is ambiguous, ask one focused clarification question.

Review checklist:

- authentication and authorization
- input validation
- output escaping / XSS
- SQL/query safety
- file upload / filesystem access
- secrets and sensitive config
- CSRF/session/cookie behavior
- dependency or package risk
- unsafe redirects or URLs
- logging of sensitive data

Output:

## Summary

<Short verdict>

## Findings

For each finding:

- severity: low | medium | high | critical
- evidence
- risk
- recommended fix
- files involved

## Non-issues

<Things checked that appear safe>

## Recommended next step

<One concrete action>
