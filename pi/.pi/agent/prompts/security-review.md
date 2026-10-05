---
description: Perform a focused security review without modifying files
argument-hint: "<scope>"
---

Perform a focused, read-only security review of: $ARGUMENTS

Use `security-audit` in guidance mode, not its full audit workflow. Do not create artifacts, modify files, or run broad scans by default. Ask one focused question if scope is ambiguous.

Inspect only relevant trust boundaries: authentication/authorization, input/output validation, SQL, files/uploads, secrets, CSRF/session/cookies, dependencies, redirects, and sensitive logging. Prefer source evidence to generic checklists; label unverified candidates as needing validation, not confirmed vulnerabilities.

Use direct tools for ordinary inspection. Load `ops` and delegate only an independent evidence question whose benefit exceeds the handoff cost.

Return a short verdict; concrete findings with severity, evidence, risk, smallest fix, and affected files; checked non-issues; and one useful next action.
