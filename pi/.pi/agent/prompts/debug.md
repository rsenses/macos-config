---
description: Diagnose and fix a bug with a minimal, evidence-driven workflow
argument-hint: "<error or symptom>"
---

Use the `dev` and `ops` skills.

Goal:
Diagnose and fix the bug described below using the smallest safe change.

Bug / symptom:
$ARGUMENTS

Rules:

1. Do not guess the root cause.
2. Reproduce or locate the failure first.
3. Read the relevant code before editing.
4. Keep diagnosis in the main agent if the issue is nuanced or the user has already corrected an interpretation.
5. Use `scout` only to locate relevant files or references.
6. Use `researcher` only if framework/library behavior matters.
7. Use `worker` only for a clearly scoped surgical fix.
8. Do not broaden scope or refactor unrelated code.
9. If the same hypothesis fails twice, stop and reassess.
10. Use the cheapest credible validation after the fix.

Workflow:

1. Summarize the observed failure.
2. Gather minimal evidence.
3. Identify the most likely root cause.
4. Propose the smallest fix.
5. Apply the fix.
6. Validate with the narrowest relevant command.
7. Add a concise daily note.

Final output:

- failure
- root cause
- files changed
- validation run
- result
- remaining risks
