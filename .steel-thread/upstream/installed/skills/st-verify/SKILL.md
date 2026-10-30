---
name: st-verify
description: The gates around writing a Simple or Complex task's code from its Approved design — tests first, a commit per slice, validation against the spec and design, and the diff review. Use once a task's design is Approved and before writing its code, when resuming work on a slice, or when asked to implement a planned change.
---

This is step 5 of `.steel-thread/framework/development.md`. A Trivial change doesn't use this skill; follow Trivial Changes there. Start only from an Approved design, or an Approved slicing plan at Complex rigor.

Write the code your own way. This skill adds the checks before, between, and after. Work one slice at a time, or the whole design if it has no slicing plan, and load the convention skills CONVENTIONS.md lists for the areas the slice touches.

## Each slice

1. **Tests first,** at the test points the design chose, each named for the behavior it proves, following Testing in development.md. Run them and confirm they fail for the right reason. For a bug, the reproduction from its diagnosis is the first test.
2. **Code until they pass,** then run the checks TESTING.md lists for the areas the slice touches. Don't re-run a check on code that hasn't changed since it passed.
3. **Spec coverage:** every spec rule the slice covers has a test whose name states it, or a manual test.
4. **Commit the slice,** following Commits in development.md, then checkpoint pickup.md.

## After the last slice

**Validate against the spec and design.** Run the full suite, unless TESTING.md leaves it to CI. List every commitment: each spec rule, limit, edge case, and contract, and each design decision a reviewer would check, such as a boundary or a persisted format. For each one, confirm the code does it, from a passing test that exercises it or from the code path itself; a test's name alone is not proof. For each mismatch:

- **Fix the code** when the spec is right. That is yours to do.
- **Fix the spec** when the implementation found something better, or the rule was wrong. A change users would notice is a high-judgment decision: put every such mismatch to the customer in one message, with your recommendation. Revise the spec, and send it back through review only if a use case changed.

**Review the diff.** Use the st-crit skill, as a senior reviewer for this stack, on the change's whole diff against its base, with the spec and design. Fix what it finds, or settle it with the customer as above, and re-run the checks for what changed.

As each finding is resolved, append one line to `.steel-thread/review-log.md`, creating it if needed, so the customer can later see whether the review earns its cost. Record what happened, not whether it was worth it:

```
2026-11-03 · T-012 · MAJOR · No test for an empty vault · fixed
```

The outcome is one of `fixed` (the code or tests changed), `spec changed`, `rejected`, or `accepted risk`. A review with no findings gets one line with `CLEAN` in place of the severity, finding, and outcome.

When no mismatch or finding is open, close the task with the st-close skill.
