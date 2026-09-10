---
description: Refine recently changed Laravel/PHP code for simplicity
---

Use the `ops`, `dev` and `laravel-simplicity` skills.

Review the entire PHP/Laravel application systematically for unnecessary complexity while preserving exact observable behavior.

You may modify the code where a simplification is demonstrated to be safe.

Do not commit.

The objective is not to minimize lines, classes or abstractions. It is to remove accidental complexity, fictitious uncertainty and duplicated framework/language behavior while preserving valid architecture, security, integrity, concurrency guarantees and useful contracts.

The central questions throughout the review are:

> What existing guarantee or capability would make this additional code unnecessary?

> What concrete value does this code buy?

> What valid execution requires it?

> What could become incorrect if it is removed?

## 1. Read the project first

Before evaluating code:

- Read the project rules and instructions.
- Load the relevant skills, especially `laravel-simplicity` and the applicable Laravel skills.
- Understand the architectural conventions already established by the project.
- Identify middleware, authentication, authorization, route bindings, Form Requests, Actions, Queries, Transformers, models, enums, casts, relationships and relevant tests.
- Confirm installed framework/package versions before relying on version-specific behavior.
- Use Laravel Boost documentation when available; otherwise prefer official version-appropriate documentation or installed source over assumptions from memory.
- Reuse evidence already available in the repository instead of repeatedly rediscovering the same contract.

Review application code broadly, but prioritize code owned by this project.

Do not refactor:

- `vendor`;
- generated files;
- framework internals;
- third-party package code.

You may inspect dependency or framework source when needed to establish an API contract.

Do not propose replacing a deliberate project convention merely because another architecture is also valid.

## 2. Review the complete application

Perform a broad review of the project-owned PHP/Laravel code.

Do not restrict the review to files changed in the current branch or session.

Search especially for the following classes of unnecessary complexity.

### Reconstructed invariants

Look for code that re-checks something already guaranteed by:

- PHP types;
- route model binding;
- scoped bindings;
- middleware;
- authentication;
- authorization boundaries;
- Form Requests;
- casts;
- enums;
- relationships;
- database constraints;
- project contracts;
- framework APIs.

Typical candidates include:

- `instanceof` checks on already guaranteed types;
- null checks on values guaranteed to exist;
- fallback branches for impossible states;
- relationship membership checks already guaranteed by scoped binding;
- duplicated validation;
- duplicated authorization;
- manual existence checks after APIs such as `findOrFail()` or equivalent guaranteed resolution.

Do not remove a check merely because it looks redundant.

First prove that no valid execution under the current contract can require it.

### Defensive programming without a reachable failure mode

Review non-trivial uses of:

- `instanceof`;
- `is_*`;
- `isset`;
- `empty`;
- `??`;
- `?->`;
- fallback values;
- `try/catch`;
- guard branches;
- nullable returns;
- type conversions;
- manual validation;
- silent fallback behavior.

For each serious candidate determine:

1. What valid execution can reach this state?
2. What contract permits it?
3. What useful recovery does this defensive code provide?
4. Is the code protecting a real failure mode, or inventing uncertainty that upstream code already resolved?

If there is no reachable failure mode, prefer the direct expression.

Do not confuse structural guarantees with mutable state.

Database state, sessions, inventory, authorization-relevant state or other concurrent data may change between validation and persistence and may legitimately require:

- re-reading;
- locking;
- transactional checks;
- uniqueness enforcement;
- fresh authorization/integrity checks.

### Reimplemented PHP features

Look for project-level APIs that merely reproduce native PHP capabilities.

Examples include unnecessary wrappers around:

- enums;
- `cases()`;
- arrays;
- iterators;
- strings;
- dates;
- native types;
- standard functions;
- language constructs.

A wrapper or convenience method must add more than a different name.

For example, a method equivalent to:

```php
Status::cases();
```

is normally unnecessary if it only returns the same information in another trivial form.

A method that expresses real domain semantics may be justified, for example:

- a meaningful subset of enum cases;
- domain labels;
- mappings;
- transition rules;
- business-specific grouping.

Distinguish a renamed primitive from a domain concept.

### Reimplemented Laravel or framework features

Look for manual implementations of behavior already available through:

- Eloquent;
- global scopes;
- local scopes;
- relationships;
- casts;
- accessors/mutators;
- Collections;
- route model binding;
- scoped bindings;
- validation;
- authorization;
- middleware;
- events;
- queues;
- pagination;
- cache;
- filesystem;
- framework extension points;
- installed package APIs.

Prefer the public framework/package API when it preserves the same semantics.

Do not reconstruct framework protocols manually if an official extension point already expresses the intent.

Confirm the exact API contract before simplifying.

Do not infer that superficially similar APIs provide identical guarantees.

For example:

- Eloquent queries may apply global scopes.
- `Rule::exists()`, `Rule::unique()` or table query builders may not provide the same behavior.

### Speculative abstractions

Review critically:

- Services;
- Repositories;
- interfaces;
- DTOs;
- Actions;
- Queries;
- Transformers;
- helpers;
- traits;
- wrappers;
- factories;
- managers;
- processors;
- generic abstractions;
- configuration layers;
- extension points;
- reusable utility classes.

Do not consider an abstraction wrong because of its category, body size or number of implementations.

For each suspicious abstraction ask:

> What would objectively become worse if this abstraction disappeared and the consumer used the underlying capability directly?

An abstraction may justify its existence through:

- domain semantics;
- an architectural boundary;
- integration with an external system;
- trust or security boundaries;
- lifecycle management;
- transactional/integrity behavior;
- cohesive complexity;
- meaningful shared behavior;
- significant reuse;
- concrete testability;
- concrete maintenance benefits.

Do not accept vague justifications such as:

- "we may need it later";
- "it is more decoupled";
- "it is cleaner";
- "it makes implementation swappable";
- "it is a best practice";

unless the current project demonstrates the corresponding need.

Respect deliberate architectural boundaries such as Actions, Queries or Transformers even when their implementations are short, provided they have a real architectural or semantic role.

### Unnecessary indirection

Look for:

- methods that only delegate;
- methods that only rename another operation;
- classes that only forward to another class;
- wrappers without semantics;
- chains of layers that do not transform behavior or data;
- trivial getters/helpers;
- unnecessary intermediate variables;
- pass-through abstractions.

Do not remove an indirection that represents a useful boundary or contract.

### Dead or redundant processing

Look for:

- values normalized and then always discarded;
- unreachable branches;
- transformations whose results cannot be observed;
- obsolete behavior left after narrowing a contract;
- unused calculated data;
- duplicated normalization;
- duplicated conversions;
- duplicate queries;
- checks repeated between layers without a new failure mode;
- fallbacks that can never be returned through valid flows.

When a contract has been narrowed, check whether old processing survived unnecessarily.

### Premature reuse and genericity

Look for abstractions generalized for hypothetical future use:

- unused configuration options;
- generic APIs with one actual use case;
- universal helpers around one concrete operation;
- factories with one meaningful possibility;
- interfaces introduced only for hypothetical implementation changes;
- extension points without real consumers;
- parameters supporting variants that do not exist;
- generalized infrastructure created before a second requirement appears.

Do not use caller count as the sole criterion.

One implementation can justify an interface when it defines a real external/trust boundary.

Several callers do not automatically justify a helper if it merely hides a clearer native operation.

## 3. Follow the real flow before deciding

Do not judge isolated snippets.

For every meaningful candidate inspect the relevant flow, including where applicable:

- routes;
- middleware;
- binding configuration;
- controllers;
- Form Requests;
- policies;
- Actions;
- Queries;
- Transformers;
- models;
- casts;
- relationships;
- jobs;
- commands;
- imports;
- external inputs;
- tests;
- direct callers;
- events;
- side effects;
- transactions;
- locks;
- constraints;
- configuration;
- targeted git history when it materially explains the code.

Determine the actual current contract.

A PHPDoc annotation is not equivalent to runtime enforcement.

A Form Request proving a scalar is valid does not necessarily mean it was converted to a specific PHP type.

Authentication does not automatically prove a particular concrete user class unless the configured guard/provider and project contract establish that.

A database foreign key does not necessarily mean a related soft-deleted model remains visible through an Eloquent relationship.

Prefer demonstrated guarantees over assumptions.

## 4. Classify before modifying

For each serious candidate classify it as one of:

### SIMPLIFY

There is sufficient evidence that the code is unnecessary under the current contract.

### PRESERVE

A reachable failure mode, useful boundary, security/integrity requirement or meaningful behavior justifies it.

### INVESTIGATE

The available evidence is insufficient.

When classifying as `INVESTIGATE`, identify the exact missing fact and investigate that narrow question where possible.

Do not invent a defensive fallback merely because the answer is not immediately obvious.

Useful category labels include:

- `REDUNDANT_INVARIANT_CHECK`
- `REDUNDANT_TYPE_CHECK`
- `UNNECESSARY_NULLABILITY`
- `DUPLICATED_VALIDATION`
- `REIMPLEMENTED_PHP_FEATURE`
- `REIMPLEMENTED_LARAVEL_FEATURE`
- `REIMPLEMENTED_FRAMEWORK_FEATURE`
- `DEFENSIVE_PROGRAMMING_WITHOUT_FAILURE_MODE`
- `SPECULATIVE_ABSTRACTION`
- `UNNECESSARY_INDIRECTION`
- `PREMATURE_REUSE`
- `DEAD_TRANSFORMATION`

These are search lenses, not automatic verdicts.

Do not create findings merely to populate categories.

A few well-demonstrated simplifications are better than a large list of subjective opinions.

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

Do not automatically convert every finding into a permanent rule.

For recurring patterns, distinguish:

### A — PHP/Laravel general

A language/framework behavior that generalizes beyond this repository.

### B — Agent reasoning

A general reasoning principle such as requiring a reachable failure mode before adding defensive code.

### C — Project invariant

A fact that is only true because of this application's architecture, routes, consumers or domain.

Do not export category C as universal Laravel guidance.

Do not create or modify skills, project rules or global agent instructions unless explicitly requested.

If a recurring pattern appears valuable for future guidance, report it as:

`RULE_CANDIDATE`

For each candidate include:

- the pattern;
- representative examples;
- the general principle;
- A/B/C classification;
- confidence.

Do not write the permanent rule during this task.

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
