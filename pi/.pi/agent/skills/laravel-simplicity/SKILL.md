---
name: laravel-simplicity
description: "Prevent unnecessary complexity when writing, reviewing or refactoring PHP/Laravel code. Use before adding defensive checks, nullable fallbacks, wrappers, helpers, interfaces, DTOs, Actions or reusable abstractions, and when investigating overengineering, duplicated validation or reimplemented framework features. Trace real contracts and consumers; distinguish simplify, preserve and investigate. Complements project conventions rather than replacing them."
---

# Laravel Simplicity

## Objective

Ask: **What existing guarantee or capability would make this additional code unnecessary?**

Choose the simplest expression that preserves the required behavior, security, integrity and useful project boundaries. Do not optimize for line count or class count. Do not infer the author's motives.

This is a reasoning workflow, not a general architecture audit. Stay within the requested scope. A review does not authorize edits, new rules, dependency changes or refactors.

## Before generating code

Read applicable project guidance and nearby implementations. Confirm the installed versions of APIs you intend to use. Use Laravel Boost documentation when available, otherwise official version-appropriate documentation or installed source. Reuse evidence already collected; do not launch a whole-project investigation for a local decision.

For each non-trivial defensive branch or abstraction, identify:

1. **Input contract:** what can actually arrive, and who enforces it?
2. **Missing guarantee:** what does that contract not establish?
3. **Reachable failure:** what valid execution requires this branch?
4. **Existing capability:** can PHP, Laravel or an installed dependency already express this behavior?
5. **Concrete benefit:** what semantics, boundary, complexity or meaningful duplication does the proposed abstraction handle?

If no benefit remains, use the direct expression. If evidence is missing, investigate the narrow question rather than inventing a fallback or deleting a safeguard. Do not narrate this checklist for every trivial edit.

## Evaluate necessity before syntax

When reviewing a defensive check, first decide whether the condition
needs to be checked at this point.

If an established contract already resolves it, remove the redundant
check while preserving any remaining authorization or domain decision.

If the condition distinguishes reachable states, preserve it. Rewriting
an equivalent required check, such as `instanceof` versus a null
comparison for a proven `T|null` value, is not by itself a simplification.
Leave equivalent syntax to project conventions and tooling.

For every proposed change, identify the unnecessary condition, work,
duplication or indirection actually removed. Do not narrow a supported
contract, hide a check in a wrapper, or change failure behavior merely
to make code appear simpler.

No change is a valid outcome.

## Trace the real flow

For a candidate, follow callers to the point being reviewed:

- Routes, middleware order, binding declarations and scoped relationships.
- Authentication guard/provider and authorization boundary; authentication alone does not prove a particular application User class.
- Form Request preparation, authorization and validation order.
- Native parameter/return types, casts, nullability and persistence constraints.
- Actions, commands, jobs, imports and direct consumers in tests.
- Model scopes, loaded relations and deliberate architecture boundaries.
- Relevant tests and, when it can explain a candidate, targeted history.

A PHPDoc annotation is not runtime enforcement. Form Request validation does not necessarily cast scalar values. A foreign key does not guarantee that a soft-deleted related model is visible through Eloquent. Do not inspect production data or secrets just to establish a source-level contract.

## Distinguish stable guarantees from changing state

A bound model has been resolved; a required validated key has passed validation. Do not recreate hypothetical null/type alternatives solely because a framework accessor has a broad static return type.

Database state can change after validation. Re-reading under a transaction or lock can protect a real invariant. Preserve uniqueness constraints, authorization and transactional semantics; validation alone does not prevent concurrent conflicts.

Check the exact API: Eloquent global scopes are not automatically applied by `Rule::exists`, `Rule::unique` or a table query builder. Optional relations and external input retain their real failure modes.

## Evaluate abstractions without architectural preference

An abstraction can earn its place through **any** concrete benefit:

- Domain meaning beyond renaming an operation.
- A real integration, trust, lifecycle or application boundary.
- Cohesive complexity or meaningful behavior shared by actual consumers.
- A concrete testability or maintenance improvement.

Do not introduce speculative consumers, configuration knobs or generic frameworks. One implementation is not proof an interface is unnecessary; several callers are not proof a helper is useful. Existing Actions, Queries and Transformers may intentionally establish boundaries even with short bodies.

Prefer native enums, casts, Collections, relationship APIs and framework extension points when they preserve semantics. A wrapper around `cases()` with no added meaning is suspect; a domain subset, labels or a mapping can be meaningful. Do not replace a domain workflow with a familiar API until restoration, events, counters, ordering and failure behavior have been compared.

## Final removal pass

For the changed flow, ask:

- Is an invariant checked again without a new failure mode?
- Does a fallback conceal a broken contract instead of recover from a valid failure?
- Is a framework mechanism being parsed or reconstructed manually?
- Are normalized values subsequently discarded unconditionally?
- Does a new indirection merely rename an existing operation?
- Did narrowing a contract leave obsolete branches or transformations?

Compare the simplest alternative against observable behavior: responses, errors, authorization, persistence, events, transactions, side effects and supported consumers. Avoid cosmetic rewrites and unrelated cleanup.

## Review output

Classify each serious candidate as:

- **SIMPLIFY:** sufficient evidence of unnecessary code under the current contract.
- **PRESERVE:** an actual failure mode or useful abstraction justifies it.
- **INVESTIGATE:** evidence is insufficient; state the precise missing fact.

For reported findings include location, behavior, existing guarantee/capability, reachable failure mode, direct alternative and confidence. Never claim tests were run if only read. A few demonstrated findings beat a quota of opinions.

Useful category labels include `REDUNDANT_INVARIANT_CHECK`, `REDUNDANT_TYPE_CHECK`, `UNNECESSARY_NULLABILITY`, `DUPLICATED_VALIDATION`, `REIMPLEMENTED_PHP_FEATURE`, `REIMPLEMENTED_LARAVEL_FEATURE`, `DEFENSIVE_PROGRAMMING_WITHOUT_FAILURE_MODE`, `SPECULATIVE_ABSTRACTION`, `UNNECESSARY_INDIRECTION`, `PREMATURE_REUSE` and `DEAD_TRANSFORMATION`. These are search lenses, not automatic verdicts.

When implementing an authorized simplification, update focused behavioral tests and run the affected checks, formatting and changelog workflow required by the project. Test retained security and failure behavior, not exact implementation text. Do not add permanent test dependencies or brittle regex rules to detect semantic complexity.

## Keep knowledge at the right level

- **A — PHP/Laravel general:** demonstrated framework/language behavior, qualified by version and API where necessary.
- **B — Agent reasoning:** identify contracts, failures, capabilities and concrete benefits before generating code.
- **C — Project invariant:** route topology, consumers, domain constraints and deliberate architecture choices. Verify locally; never export them as universal Laravel advice.

Only record durable guidance when requested or required by the project's workflow. Use the project's shared-rule mechanism, not personal memory. Do not copy every finding into a separate prohibition.

## Calibration

Read [the calibration cases](references/calibration.md) when reviewing suspected complexity or evaluating changes to these instructions. They include both simplifications and necessary safeguards. For evaluation, decide from the scenario before reading its expected result. Passing these examples checks reasoning coverage, not guaranteed behavior on future projects or models.
