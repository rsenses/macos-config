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
2. Build a tight, red-capable feedback loop before theorising: one command or test that exercises the real path and asserts the user's exact symptom.
3. Reproduce the reported failure, then minimise the scenario until every remaining input or step is load-bearing.
4. Read the relevant code before editing.
5. Redact secrets from commands, logs, traces, and captured artifacts.
6. Keep diagnosis in the main agent if the issue is nuanced or the user has already corrected an interpretation.
7. Use `scout` only to locate relevant files or references.
8. Use `researcher` only if framework/library behavior matters.
9. Use `worker` only for a clearly scoped surgical fix.
10. Do not broaden scope or refactor unrelated code.
11. If the same hypothesis fails twice, stop and reassess.
12. Use the cheapest credible validation after the fix.

Workflow:

1. Summarize the observed failure and the exact expected behavior.
2. Build, run, and record a tight feedback loop; if no red-capable loop can be built, stop and report what access or artifact is missing.
3. Minimise the reproduction and write 3–5 ranked, falsifiable hypotheses. Show them to the user before testing; proceed with the ranking unless the user redirects it.
4. Test one hypothesis at a time with one-variable probes at the boundary that distinguishes it. Tag temporary logs with a unique `[DEBUG-...]` prefix.
5. Apply the smallest root-cause fix and add a behavioral regression test at the highest correct public seam. Re-run the original loop.
6. Remove tagged instrumentation and throwaway harnesses, then run the narrowest relevant validation.

Final output:

- failure
- root cause
- files changed
- validation run
- result
- remaining risks
