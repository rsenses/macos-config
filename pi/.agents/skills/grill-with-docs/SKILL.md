---
name: grill-with-docs
description: "Use when the user requests an interactive, question-by-question challenge of a plan against the project's domain model, terminology, code, and documented decisions, with glossary and ADR updates as decisions are resolved."
---

<what-to-do>

Work through the plan's material decisions and their dependencies until we reach a shared understanding. Resolve prerequisites before dependent questions; after each answer retain settled decisions and update what remains open.

Ask one focused question at a time, with a recommended answer and a brief reason; wait for feedback before continuing. Discover repository facts yourself rather than asking the user, using ops' selective-delegation limits.

Stop once behavior, constraints, non-goals, data implications and acceptance are clear enough. Summarize decisions and unresolved questions in the existing ops brief; do not automatically plan or implement.

Honor the invoking role's permissions and output contract. In read-only reviews, propose documentation updates instead of editing files or starting an interview.

</what-to-do>

<supporting-info>

## Domain awareness

During codebase exploration, use existing glossary and ADR locations rather than creating parallel documents. Otherwise use the conventions below:

### Default layout

Single context: root `CONTEXT.md` and `docs/adr/`. A root `CONTEXT-MAP.md` indicates multiple contexts; read it to locate each context's glossary and ADRs. Root `docs/adr/` holds system-wide decisions.

Create files lazily — only when you have something to write. If no glossary exists, create `CONTEXT.md` when the first domain term is resolved. If no ADR location exists, create `docs/adr/` when the first ADR is needed.

## During the session

### Challenge against the glossary

Immediately flag conflicts with the project's glossary and ask which meaning is intended.

### Sharpen fuzzy language

For vague or overloaded language, propose a precise canonical term.

### Discuss concrete scenarios

Stress-test domain relationships with concrete edge-case scenarios that clarify concept boundaries.

### Cross-reference with code

Check claimed behavior against code; surface contradictions and ask which behavior is intended.

### Update the glossary inline

When a term is resolved, update the relevant glossary right there; do not batch resolved terms. Preserve its existing format, or use [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md) for a new `CONTEXT.md`.

Keep the glossary domain-only: no implementation details, specs, scratch notes or implementation decisions.

### Offer ADRs sparingly

Only offer to create an ADR when all three are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip the ADR. Use the format in [ADR-FORMAT.md](./ADR-FORMAT.md).

</supporting-info>
