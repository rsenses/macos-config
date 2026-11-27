# Brief and Output Contracts

Every brief uses these headings:

- **Goal**: bounded outcome/scope and write permissions.
- **Known**: decisions, constraints, invariants, and existing changes to preserve.
- **Evidence**: checked paths/ranges/URLs or excerpts, plus the remaining unknown.
- **Acceptance**: observable result, including security and applicable changelog requirements.
- **Checks**: concrete permitted checks; never invent provider calls.
- **Stop**: ambiguity, scope conflict, missing evidence, or repeated failure without new evidence.

Pass established evidence, the remaining question, original request and later clarifications—not a transcript, rediscovery request or only the plan/implementer's account. Separate decisions, verified facts and assumptions in Known/Evidence. Children run with `--no-skills`: put relevant skill criteria in Known as short excerpts, or exact readable paths/sections with explicit read instructions when needed. Prefer sufficient excerpts; do not require full-skill reads for trivial work. Request concise evidence but complete actionable planning designs; integrate each locally verified result once into the canonical plan, without duplicate reports.

Child output starts with **Status** (`complete`, `partial`, `blocked`, `failed`, `cancelled`, `timed_out`), then its role's findings/changes, evidence, checks, and unresolved items. Workers return **Status / Changes / Evidence / Checks / Unresolved**. Name their validation policy (`no-tests`, `targeted-check`, `add-test`, `test-first`, `defer-validation`) and the concrete command or reason.
