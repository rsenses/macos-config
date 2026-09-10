---
description: Create focused tests for the current plan before implementation
argument-hint: "[optional focus area]"
---

Use the `dev` and `ops` skills.

1. **Discovery**: Inspect existing tests and project conventions. Read the relevant `CONTEXT.md` and ADRs when they exist.
2. **Choose the seam**: Test through the highest existing public interface that can observe the behavior. Do not test private methods, internal structure, or implementation-only collaborators.
3. **Write one vertical slice**: Create or update the smallest behavior-focused test for the agreed plan/behavior ($ARGUMENTS). Use an independent expected value or example; avoid tautological assertions and exhaustive horizontal suites.
4. **Verification**: Run the narrowest relevant test command. If production code is not implemented yet, a failing test is expected; report that red state instead of changing production code to force green.
5. **Summary**: List the seam, tests added, behavior covered, red/green result, and remaining implementation gap.

_Note: Follow project patterns and keep the local pragmatic testing posture. Do not implement production code yet._
