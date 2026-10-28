---
name: laravel-code-simplifier
description: "Use when the user requests a systematic, application-wide review and simplification of project-owned PHP/Laravel code while preserving observable behavior. For local complexity decisions during ordinary implementation or review, use laravel-simplicity."
---

Read `ops`, `dev` and `laravel-simplicity` before reviewing. The latter is the authority for simplification criteria, flow tracing, evidence, safeguards and calibration; apply it throughout, not a substitute summary here. For a child, supply readable skill paths in the ops brief: loaded skills are not inherited and discovery may be disabled. Read the supplied paths explicitly; the installed default for the reasoning skill is `~/.pi/agent/skills/laravel-simplicity/SKILL.md`. If unavailable, report the missing reference rather than inventing criteria.

Review the entire project-owned PHP/Laravel application, not only changed files. You may apply demonstrated safe simplifications; do not commit. Remove accidental complexity, fictitious uncertainty and duplicated native behavior, not useful architecture or guarantees. Line/class counts are not the objective.

## 1. Read the project first

Read project rules, applicable Laravel skills and established architectural conventions. Identify middleware, authentication/authorization, bindings, Form Requests, Actions, Queries, Transformers, models, enums, casts, relationships and relevant tests. Confirm installed versions using Laravel Boost documentation when available, otherwise official version-appropriate docs or installed source; reuse established evidence.

Prioritize project-owned code. Do not refactor `vendor`, generated files, framework internals or third-party packages; inspect dependencies only as needed to establish contracts. Another valid architecture is not grounds to replace a deliberate convention.

## 2. Review the complete application

Systematically scan the whole application using the criteria in `laravel-simplicity`. Prioritize serious candidates, not a category quota:

- **Reconstructed invariants:** redundant type/null/existence, membership, validation or authorization checks against types, bindings/scoped relationships, middleware, authentication/authorization, Form Requests, casts, enums, database/project/API contracts; e.g. existence checks after `findOrFail()`.
- **Unjustified defenses:** non-trivial `instanceof`, `is_*`, `isset`, `empty`, `??`, `?->`, fallbacks, `try/catch`, guards, nullable returns, conversions, manual validation and silent recovery.
- **Reimplemented capabilities:** wrappers around PHP enums/`cases()`, arrays, iterators, strings, dates, types, functions or constructs; manual Eloquent/scopes/relationships/casts/accessors/mutators, Collections, bindings, validation, authorization, middleware, events, queues, pagination, cache, filesystem, extension-point or installed-package behavior.
- **Speculative abstractions:** Services, Repositories, interfaces, DTOs, Actions, Queries, Transformers, helpers, traits, wrappers, factories, managers, processors, configuration layers, extension points and utilities.
- **Unnecessary indirection:** delegation/renaming/forwarding, non-transforming layers, trivial getters/helpers, intermediate variables and pass-through contracts.
- **Dead/redundant processing:** discarded normalization, unreachable branches, unobservable transformations, obsolete narrowed-contract behavior, unused calculations, duplicate normalization/conversions/queries, repeated checks without new failure modes and unreachable fallbacks.
- **Premature genericity:** unused options, hypothetical variants/consumers, universal helpers for concrete operations, single-possibility factories and interfaces for hypothetical swaps.

These are search lenses, not verdicts. Apply the reasoning skill's distinctions: structural guarantees versus mutable state, native primitives versus domain semantics, and real boundaries versus speculative reuse. Preserve necessary re-reads, locks, transactions, uniqueness and fresh authorization/integrity checks for changing database, session, inventory or other concurrent state. Neither body size nor caller/implementation count proves value; vague cleanliness, decoupling, future need or swappability claims require a demonstrated current benefit.

## 3. Follow the real flow before deciding

For every meaningful candidate, trace the actual contract using `laravel-simplicity`: include applicable routes, middleware, bindings, controllers, Form Requests, policies, Actions/Queries/Transformers, models, casts, relations, jobs, commands, imports, external inputs, tests and direct callers. Inspect events, side effects, transactions, locks, constraints, configuration and targeted history when material. Do not judge isolated snippets or assume runtime guarantees from annotations, validation, authentication or foreign keys.

## 4. Classify before modifying

Use the reasoning skill's classifications:

- **SIMPLIFY:** sufficient evidence that code is unnecessary under the current contract.
- **PRESERVE:** a reachable failure, useful boundary or behavior justifies it.
- **INVESTIGATE:** name the precise missing fact and investigate that narrow question where possible; do not invent a fallback.

Use its category labels, plus `REIMPLEMENTED_FRAMEWORK_FEATURE` when applicable, as lenses rather than quotas. A few demonstrated findings beat subjective volume.

For each reported simplification, state what unnecessary condition, work, duplication or indirection was removed and which established contract makes removal safe. Equivalent syntax alone is not a finding; separate tooling-required normalizations from substantive changes.

## 5. Apply demonstrated simplifications

You may modify the code.

Apply only candidates classified as `SIMPLIFY` with sufficient confidence.

Preserve exact observable behavior.

In particular preserve:

- authentication;
- authorization;
- validation;
- database constraints;
- transactional behavior;
- concurrency guarantees;
- events;
- side effects;
- domain semantics;
- supported consumers;
- public contracts;
- deliberate architecture boundaries.

Prefer the smallest coherent change.

Do not change code merely because another valid implementation is shorter or more idiomatic.

A change requires a demonstrated simplification under the current project's contracts.

Do not introduce one new abstraction merely to eliminate another unless the new abstraction has a clear demonstrated benefit.

Do not perform cosmetic cleanup unrelated to the candidate being simplified.

Do not redesign the project's architecture as part of this task.

## 6. Perform a second removal pass

After simplifying a flow, inspect the changed area again.

A valid simplification may leave behind:

- unused imports;
- dead variables;
- unreferenced private methods;
- obsolete branches;
- unused parameters;
- unnecessary normalization;
- helpers with no remaining consumers;
- tests that only protected removed implementation details.

Remove only artifacts that became genuinely unnecessary because of the demonstrated simplification.

Do not expand this into unrelated cleanup.

## 7. Tests and verification

Update tests where necessary to preserve or demonstrate the real behavioral contract.

Prefer behavioral tests.

Do not add tests whose purpose is merely to freeze implementation details such as:

- the existence of a particular internal class;
- exact internal method structure;
- CSS classes;
- regex checks reproducing these instructions;
- arbitrary abstraction choices.

If an existing test only protects unnecessary implementation detail rather than behavior, remove or replace it with a test of the actual contract when appropriate.

Run the project's applicable verification workflow.

Use existing project tooling rather than inventing a parallel verification process.

This may include, depending on the project:

- targeted Pest tests;
- the relevant test suite;
- Pest architectural tests;
- PHPStan;
- Rector;
- Pint;
- project-specific validation commands.

Run targeted checks first where appropriate, then broader checks required by project rules.

Do not claim a check passed unless it was actually executed.

Do not commit.

## 8. Keep knowledge at the correct level

Use `laravel-simplicity`'s A/B/C distinction (PHP/Laravel general, agent reasoning, project invariant); never export C as universal advice or turn every finding into a rule.

Do not create or modify skills, project rules or global instructions unless explicitly requested. Report recurring patterns worth future guidance as `RULE_CANDIDATE`, with pattern, representative examples, general principle, A/B/C classification and confidence. Do not write permanent rules during this task.

## 9. Final review

Before finishing, review the resulting diff itself using `laravel-simplicity`.

Ask:

- Did any simplification accidentally weaken a real contract?
- Did we turn a clear failure into a silent fallback?
- Did we remove a necessary concurrency or transactional safeguard?
- Did we replace domain semantics with a generic framework primitive?
- Did we introduce a new abstraction unnecessarily?
- Did we leave redundant code behind?
- Did we modify anything merely because it looked different from our preferred style?

Correct any issue found before finishing.

Run:

```bash
git diff --check
git status --short
git diff --stat
```

and any required project checks.

Do not commit.

## 10. Final output

Provide a concise report organized by:

### Changes made

Group meaningful changes by pattern rather than narrating every changed line.

For each important pattern explain briefly what existing guarantee or capability allowed the simplification.

### Preserved intentionally

Mention notable candidates that looked unnecessary but were retained because a real failure mode, boundary or behavior justified them.

### Investigated but unresolved

List only meaningful questions that could not be resolved from available repository evidence.

State the precise missing fact.

### Rule candidates

List recurring patterns worth considering later for improvements to:

- `laravel-simplicity`;
- Laravel/project rules;
- static/tooling enforcement.

Do not create those rules now.

### Verification

List the checks actually executed and their result.

### Result

Include:

- files modified;
- insertions/deletions;
- important categories eliminated;
- any remaining risk worth knowing.

Do not present line-count reduction as evidence of quality by itself.

The success criterion is:

> Less accidental code and less fictitious uncertainty, with the same meaningful behavior and guarantees.
