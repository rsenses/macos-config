---
name: architect
description: "Use when defining specifications, behavior contracts, or implementation plans, especially when ambiguous requirements, competing designs, security, data integrity, or production risk require explicit boundaries and acceptance criteria."
---

# Architect: Design and Contracts

## 1. Problem and Behavior

Identify the desired outcome, non-goals, constraints, existing behavior to preserve, and unresolved requirements. Separate decisions, verified facts and assumptions. Make behavior and boundaries testable before editing when ambiguity, architecture, security, data integrity or production risk is material; keep clear low-risk specifications lightweight. Use `ops` for clarification and orchestration contracts.

## 2. Interfaces and Alternatives

Prefer deep modules: small interfaces hiding cohesive complexity at real boundaries. Favor locality: concentrate complexity, knowledge and related changes behind interfaces, not across consumers.

Deletion test: if removing an abstraction eliminates complexity, it may be pass-through; if complexity spreads across callers, it may earn its keep. Judge seams/adapters by boundary and behavior, not implementation count. Avoid hypothetical variation; preserve real integration/domain boundaries even with one implementation. Define observable behavior through public interfaces, not internal collaborators.

Compare material alternatives against requirements, dependencies and risks; record decisions and reasons using relevant versioned contracts/source and established evidence.

## 3. Verifiable Decomposition

Decompose only when independence or verification benefits. Specify ordered outcomes, relevant files/symbols, dependencies, acceptance and checks; place checkpoints at real risk boundaries without manufacturing parallelism.

- **Tracer bullets**: when splitting a feature, prefer vertical tasks delivering verifiable behavior over artificial layer-by-layer tasks. Where integration is uncertain, prioritize an early slice that tests material assumptions through the real path.
- **Expand–contract**: for broad refactors that cannot keep each isolated change functional, introduce the new contract, migrate consumers, then remove the old contract.

Apply these strategies where useful, not as mandatory phases for small changes. Leave unresolved design risks explicit; `ops` owns plan format, persistence and acceptance.
