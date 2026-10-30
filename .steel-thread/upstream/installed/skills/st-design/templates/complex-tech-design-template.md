---
name: feature tech design
description: feature description
task: T-NNN
rigor: Complex
trigger: [the Complex trigger from development.md's Rigor Levels, such as "not revertible: adds a settings field"]
date: YYYY-MM-DD
review iteration: N
status: Draft / Approved / Blocked
---

# Tech Design: Bug or Feature Name

## 1. Context

\[Problem and why now.\]

## 2. Goals / Non-Goals

\[Testable outcomes; at least two explicit non-goals with rationale.\]

## 3. Open Questions

\[Unresolved decisions; do not hide uncertainty.\]

## 4. Requirements

\[The task's spec, and the lasting documents that already promise behavior in this area.\]

### Spec Review

Quote relevant claims verbatim: the spec's rules, ARCHITECTURE.md, and the existing promises that hold the area's current behavior ("Planning Docs Are Scaffolding" in `.steel-thread/framework/docs-layout.md`). List sources reviewed with no relevant claims.

| Source | Direct claim | Changes it? |
| ------ | ------------ | ----------- |

## 5. Current System Audit

Verify from source; include applicable entry points, state owners, IPC/event wiring, registration, consumers, restore/reload, cleanup, and tests.

| Concern | Source evidence | Current behavior / gap |
| ------- | --------------- | ---------------------- |

| Failure mode | Applicable / Not applicable / Checked—no issue / Accepted risk | Evidence |
| ------------ | -------------------------------------------------------------- | -------- |

## 6. Proposed Design

\[Each component or layer the change touches, the boundaries between them, state ownership, and one end-to-end success/failure flow. Add a diagram when &gt;3 components participate.\]

| New state | Owner | Lifetime | Persist? | Why |
| --------- | ----- | -------- | -------- | --- |

| Operation | Triggers | Caller | Boundary | Handler/event | Registration | Consumer/state | Restore/cleanup | Test | Evidence |
| --------- | -------- | ------ | -------- | ------------- | ------------ | -------------- | --------------- | ---- | -------- |

| Guarantee | Mechanism | Owner | Linearization point | Failure behavior | Proof |
| --------- | --------- | ----- | ------------------- | ---------------- | ----- |

For awaits, dialogs, lock releases, events, reloads, check-then-act, or concurrent entry points:

| Boundary | Concurrent event | Invariant | Linearization point | Recovery |
| -------- | ---------------- | --------- | ------------------- | -------- |

### Red Flags Audit

Screen the design above — and every alternative in §11 — against `../design-red-flags.md`.

| Red flag               | Present? | If present, why acceptable |
| ---------------------- | -------- | -------------------------- |
| Shallow module         |          |                            |
| Information leakage    |          |                            |
| Temporal decomposition |          |                            |
| Pass-through method    |          |                            |

## 7. Interface Contract

\[Every API, command, or message the change adds or changes, across any process, network, or language boundary.\]

| Interface | Inputs | Output | Errors | Async? |
| --------- | ------ | ------ | ------ | ------ |

\[For events: name, payload, emitter, listeners, ordering/delivery. State whether the types on each side of a boundary are generated or kept in sync by hand.\]

## 8. Data Model & Persistence

\[Mechanism, schema/version, migration, rollout ordering, retention/removal.\]

## 9. Capabilities & Security

\[Minimum permissions and scopes, trust boundaries, input validation, attack surface.\]

## 10. Cross-Platform

Name the baseline platform, then one row for every other platform, browser, or runtime the product supports: what's different and how it's verified. "None" is a complete answer, a missing row is not. If the product runs in one environment only, say so and skip the table.

| Platform | Difference from baseline | Verified how |
| -------- | ------------------------ | ------------ |

## 11. Alternatives / Reuse / Proportionality

| Checked | Stdlib / native / existing dep / new dep | Covers? | Why not | Ceiling / upgrade path |
| ------- | ---------------------------------------- | ------- | ------- | ---------------------- |

| Rare case | Cost to support | Requirement change that deletes it | Recommend |
| --------- | --------------- | ---------------------------------- | --------- |

\[At least two real alternatives — see §3 (Draft) of `st-design` for the reuse/proportionality bar. Break ties on interface depth (`../design-red-flags.md`) — prefer hiding more behind a smaller surface, not a shorter call chain.\]

## 12. Implementation Slicing Strategy

\[Vertical runnable sequence, or smallest enabling design change. Name ceilings and upgrade paths.\]

## 13. Testing Strategy

Every declared error and lifecycle/concurrency failure needs automated or manual proof. Cover applicable partial success, stale dialog state, missing wiring, cleanup, reload between decision/action, and concurrent entry points. Every boundary an operation crosses needs an integration test through the real boundary, or a manual check with the reason. Every spec rule appears in the Spec rules column of at least one row.

| Test | Kind (unit / integration / UI / manual) | Spec rules proved | Regression prevented |
| ---- | --------------------------------------- | ----------------- | -------------------- |

## 14. Rollout

\[Flag or direct ship — the one universal question. Add signing impact or release rollback only when this design changes what ships or how it's packaged; otherwise "direct ship, no flag" is complete. Data migration and its rollback belong in §8, not here.\]

## 15. Reviewer Feedback

Severities, decisions, and the Source column: `.steel-thread/framework/reviews.md`.

| \#  | Finding | Severity | Cost to accept | Decision | Rationale | Next step | Arch? | Source |
| --- | ------- | -------- | -------------- | -------- | --------- | --------- | ----- | ------ |

## 16. Lasting Changes

\[What this design adds to the lasting documents, as st-design's Draft step says. The close applies these once the code is built; anything not listed here is lost when the task closes.\]

| Change | Goes to |
| ------ | ------- |
|        | ARCHITECTURE.md / CONVENTIONS.md / CONTRACTS.md / COMMON-FAILURE-MODES.md / DECISIONS.md |
