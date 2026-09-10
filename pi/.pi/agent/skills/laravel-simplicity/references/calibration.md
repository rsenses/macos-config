# Calibration cases

These are independent scenarios, not facts about the current project. For each, identify the guarantee, a reachable failure and the simplest behavior-preserving expression. Do not infer a verdict merely from a keyword such as `instanceof`, interface or Action.

| Scenario | Expected result | Reason / boundary |
| --- | --- | --- |
| An update-only Form Request receives a required model parameter, resolved by implicit binding before the request. No alternate consumers or overrides exist. It rejects non-model values again. | SIMPLIFY | Binding resolves the model or fails upstream. Keep the actual policy decision. |
| A Form Request serves both store and update, using the presence of the bound model to choose its policy. | PRESERVE | Absence is a valid creation state, not a fictitious failure. |
| A nested resource uses scoped binding, the parent relationship is configured, and the Request compares the already-bound child's parent ID again. | SIMPLIFY | The binding already enforces membership. This in-memory comparison is not a concurrency safeguard. |
| An authenticated route checks for a concrete application User type, but the guard/provider configuration and alternate callers have not been inspected. | INVESTIGATE | `auth` proves authentication under a guard, not universally that concrete class. |
| A normal Eloquent query on a SoftDeletes model explicitly adds `whereNull('deleted_at')`, without removing the global scope. | SIMPLIFY | The scope supplies that predicate. |
| A `Rule::exists` constraint excludes soft-deleted records explicitly. | PRESERVE | Database presence validation does not inherit Eloquent scopes. |
| A `withSum` value uses zero when the SQL aggregate is null for no related rows. | PRESERVE | The empty aggregate is a real state. |
| A non-null foreign key points to a soft-deletable model; the relation does not use `withTrashed`, and soft deletion is allowed. | PRESERVE | The relation can be absent despite referential integrity. |
| A non-null cast date is selected by `onlyTrashed()` from an explicitly bounded set of compatible models, then checked against mutable Carbon before formatting. | SIMPLIFY | The date contract suffices; immutable implementations must not be silently rejected. |
| A validated status is checked again after re-reading the record under a transaction lock. | PRESERVE | Another transaction may have changed the status since validation. Verify the actual locking guarantees separately. |
| A transaction persists an expired session's closure, returns a sentinel, and the caller throws after commit. | PRESERVE | Moving the exception inside could roll back the necessary closure. |
| A pure read page manually parses partial-reload headers to omit expensive props. The installed Inertia API supports lazy props with equivalent output. | SIMPLIFY | Use the framework's selection and lazy evaluation, retaining authorization. |
| An edit page bypasses a heartbeat-changing Action during a partial options reload. | PRESERVE | Filtering response props alone does not suppress eagerly executed mutations. |
| An enum helper returns a manually maintained list of all backing values, with no subset, labels, compatibility contract or other semantics. | SIMPLIFY | Derive from native enum cases; no parallel source of truth is needed. |
| An enum method returns only states available for a domain transition, or produces localized labels. | PRESERVE | This adds domain/presentation semantics that `cases()` does not supply. |
| A new repository interface has one Eloquent implementation, exactly mirrors CRUD, and has no existing architectural requirement, integration boundary or testing need. | SIMPLIFY | Hypothetical future storage is not a present benefit. |
| One implementation of a payment gateway interface isolates a real external integration and is replaced by a fake in boundary tests. | PRESERVE | A concrete boundary exists despite a single production implementation. |
| A generic helper with strategy flags is introduced for one caller because other callers might appear. The direct expression is clear and equivalent. | SIMPLIFY | Speculative reuse adds a contract and configuration without a consumer. |
| A short Action delegates persistence because the project deliberately keeps persistence out of controllers. | PRESERVE | The Action establishes the chosen application boundary. Small size alone is not evidence against it. |
| A proposed DTO duplicates validated fields; neither its consumers nor lifecycle have been examined. | INVESTIGATE | It might encode a useful immutable, transport-independent or serialization contract. Determine the actual benefit. |
| An Action normalizes strings even though its HTTP caller already did so; direct tested callers supply untrimmed input and expect normalization. | PRESERVE | The Action's actual input contract is broader than the HTTP path. |
| A method normalizes three fields and unconditionally drops them before any read, persistence or return. | SIMPLIFY | Their transformed values have no observable contribution. Keep the field allowlist. |
| An importer validates workbook headers after the upload passed extension and size validation. | PRESERVE | Transport validation does not establish file-content structure. |
| An importer catches `Throwable`; the specific library errors and desired recovery have not been examined. | INVESTIGATE | External failures justify handling, but the necessary catch breadth is not yet demonstrated. |

## Using the cases as an evaluation set

Ask the model to return a verdict, guarantee, failure mode and safe alternative from the scenario alone. Compare with the expected result afterward.

A correct verdict with an unsafe rationale is not a pass. In particular, reject reasoning that assumes validation casts all values, removes authorization, treats foreign keys as relation visibility guarantees, assumes locks work identically on every database, or removes an established layer just to reduce class count.

Include new real failures as paired simplify/preserve cases where possible. Keep uncertain cases: recognizing missing evidence is part of the objective. Do not claim cross-model effectiveness without actually evaluating those models.
