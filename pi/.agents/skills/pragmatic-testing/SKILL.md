---
name: pragmatic-testing
description: Guides proportional, evidence-focused testing without strict TDD. Use when implementing behavior, fixing bugs, changing APIs, or deciding what verification is enough. Prefer tests when they add durable confidence; avoid test ceremony when simpler validation is sufficient.
---

# Pragmatic Testing

Use tests as evidence, not ritual.

This skill replaces strict test-driven development for this workflow. A failing test first is valuable for many bug fixes and behavior changes, but it is not mandatory for every edit.

## Core principle

Choose the cheapest credible verification that proves the change works.

Prefer durable automated tests when the change affects:

- business logic,
- bug fixes with regression risk,
- public APIs or module boundaries,
- validation, authorization, permissions, billing, security, or data integrity,
- edge cases that are easy to miss manually,
- behavior that future refactors could break.

Automated tests are usually not required for:

- documentation-only changes,
- formatting or comments,
- static content,
- tiny configuration changes,
- mechanical renames,
- trivial changes already covered by type checking, linting, or framework guarantees.

## Bug fixes

For non-trivial bugs, prefer the Prove-It pattern:

1. Reproduce the bug with a focused test or minimal command.
2. Confirm the test/command fails before the fix when practical.
3. Implement the smallest fix.
4. Confirm the same test/command passes.
5. Run only the additional checks needed to catch likely regressions.

If a reproduction test would be expensive or brittle, explain the tradeoff and use a narrower verification path.

## Behavior changes

For new or changed behavior:

1. Identify the behavior contract.
2. Decide the smallest useful test level:
   - unit test for pure logic,
   - validation/request/policy test for boundaries,
   - integration or smoke test for cross-component behavior,
   - browser/runtime check for UI behavior.
3. Prefer high-signal tests over broad, slow coverage.
4. Avoid testing framework behavior or duplicated guarantees.

## Test style

- Test outcomes, not implementation details.
- Prefer real implementations or fakes over interaction-heavy mocks.
- Use clear Arrange / Act / Assert structure when it improves readability.
- Name tests as behavior specifications.
- Keep tests deterministic and isolated.
- DAMP is often better than DRY in tests: readability beats clever shared setup.

## Validation discipline

- Do not claim full validation unless the relevant checks actually ran and passed.
- Report checks that were skipped or not available.
- Do not repeat the same passing command without intervening changes; it adds no confidence.
- Prefer targeted checks during implementation.
- Reserve full suites, formatting, and CI-readiness checks for finalize/ship unless the user asks earlier or risk demands it.

## Working with subagents

For complex bugs, the main agent may ask a reviewer or worker to create a reproduction test before the fix. This helps avoid confirmation bias.

The main agent remains responsible for deciding whether the test is meaningful and whether the final evidence is sufficient.

## Verification checklist

Before finishing a behavior-changing task, confirm:

- [ ] The expected behavior or bug contract is explicit.
- [ ] The verification method matches the risk.
- [ ] Important behavior has durable coverage when practical.
- [ ] Relevant targeted checks passed, or limitations were stated.
- [ ] No tests were skipped, weakened, or deleted to make the suite pass without explicit approval.
