# docs/DECISIONS.md — Format and Rules

DECISIONS.md is the log of why: the reasoning behind choices that all future work has to follow, and what was rejected. It answers "why is it like this?" so the customer never has to reconstruct it, and so no session re-litigates a settled question by accident. It is the project's ADR log; don't keep architecture decision records anywhere else.

## Format

Newest entry first:

```markdown
## D-002 · US zip codes only · 2026-10-06
Status: Active
Context: --zip needed a scope; non-US postal codes need a different frost-date source.
Decision: Support US 5-digit zip codes only.
Why: Matches the objective; international users are listed under Not Doing.
Rejected: Any postal code with a fallback lookup — needs a second data source.
Affects: T-003, PRD.md
```

- IDs are `D-` plus three digits. A new decision takes the highest existing ID plus one; IDs are never reused.
- Status is `Active` or `Superseded by D-NNN`.
- `Rejected` and `Affects` can be omitted when there is nothing to say.

## Rules

- Entries are never edited or deleted. When a decision changes, add a new entry and change only the old entry's Status line to `Superseded by D-NNN`.
- Record a decision only if future work has to follow it, and it is also expensive to undo or likely to be proposed the other way later. A choice that shapes only the current task stays in the document where it was made: its spec, design, or slicing plan.
- Planning docs are scaffolding that nothing reads once their task closes, so DECISIONS.md is the only lasting home for a rejected alternative. The close asks of each one: "Will someone propose this again?" and proposes all of a task's entries in one approval.
- Code comments, lasting documents, and done tasks cite decisions by ID: "(D-003)".
- DECISIONS.md never states the current rule. The rule lives where it applies — CONTEXT.md, or the documents in `.steel-thread/framework/docs-layout.md`'s "Where information lives" — and cites the decision for the reason: "UI code never touches the filesystem (D-003)."
