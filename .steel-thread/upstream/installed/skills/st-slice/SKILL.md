---
name: st-slice
description: Turn an approved technical design into thin vertical implementation slices with drift checkpoints. Use when asked to slice or sequence a technical design for implementation.
---

# Slice Tech Design

This is step 4 of `.steel-thread/framework/development.md`. Use only after an Approved design exists. Revise the plan in place while the task is open.

## 1. Load

Read the design, `tech-design-slices-template.md`, `AGENTS.md`, and `docs/engineering/CONVENTIONS.md` in full, and the convention skills it lists for the areas the design touches. Read the task's spec where boundaries need it. Record the design commit; if dirty, also record `uncommitted working tree`.

If no design is named, use the one for the task in progress in TASKS.md. Ask only if that leaves more than one candidate.

## 2. Gate

Find the design's slicing strategy: `Implementation Slicing Strategy` in the Complex template, or its project-customized equivalent. Proceed only if it defines a valid vertical sequence. Otherwise create no plan: name the smallest required design change and take it back to `st-design`. Quote its conclusion in the plan.

## 3. Slice

Create `slices.md` from the template, in the same task folder as the design: `docs/work/T-NNN-<name>/slices.md`. Do not copy slices into TASKS.md: the task stays the unit of work there. Keep its detail line, through the st-tasks skill, naming the slice in progress: `Slice 2 of 4 in docs/work/T-014-first-save-filename/slices.md.`

- Prefer few slices.
- Each slice closes one cohesive, independently verifiable outcome.
- Split only for independently valuable checkpoints or unrelated risk, not time.
- Layer-only slices must name the later vertical slice they enable.
- Carry design shortcuts/ceilings into `Invalidation risk`.
- Every slice needs a plausible test or demo.

## 4. Review

Budget: one broad pass, plus one targeted blocker-verification pass if needed. All reviewers and user-supplied feedback share this budget.

Give a reviewer in a fresh context (`.steel-thread/framework/reviews.md`) only the design, plan, and this request:

```text
Review this slicing plan for non-vertical or incohesive slices, hidden dependencies, invalid predecessor states, misleading deferrals, weak demos, and vague invalidation risks. For each finding give evidence, suggested change, and severity: BLOCKER (name the slices it blocks, or the whole plan), MAJOR, MINOR, or QUESTION.
```

Classify each change:

- **SLICING:** boundaries, order, dependencies, deferral, verification.
- **DESIGN:** runtime semantics, architecture, ownership, concurrency, persistence, security, IPC, or customer behavior.
- **EXPANSION:** capability/infrastructure absent from the design.

Apply accepted SLICING changes. Route DESIGN findings back to the design and block only affected slices; do not solve them in the plan. Reject/defer EXPANSION unless the user broadens scope. Independent slices remain startable.

Decide each finding as Deciding Findings in `reviews.md` says. Use the second pass only to verify the original blocker against changed sections and dependency edges.

## 5. Verify and exit

Build the dependency graph. Confirm Slice 1 starts from current state, every later slice consumes a concrete predecessor, no hidden future work is required, deferrals preserve demos, and order matches the design.

Exit when every ready slice has a valid predecessor and demo, design findings are routed, and no applicable blocker remains. If a blocker remains, set the affected slice or plan to `Blocked` and record why. Report modified files, slice and review counts, rejected alternative, blockers/drift, readiness, and plan line count.

## Checkpoints and drift

After each slice, mark it Done, put its evidence — tests added, results, drift — in the commit message, and add a Checkpoint Log entry naming the commit. Review only affected remaining slices plus their dependency edges, and update them in place; explain why others are unchanged.

Recognize a design failure, not just a slice failure, before patching around it. A single hard case is not a design failure — some problems are legitimately complex, and complexity in the data is not complexity in the design. The signal is a pattern: the same shape of trouble recurring across two or more otherwise- unrelated slices. Tells:

- The same shape of workaround appearing in unrelated slices.
- A type needing an escape hatch to compile — `any`, a cast, an "optional" field that's always set in practice.
- Reaching for a lock or mutex where the design said the state wasn't shared.
- A later slice's caller needing to know an earlier slice's internal rules to use it correctly.

When two or more tells of the same shape appear, propose a DECISIONS.md entry for the assumption the implementation disproved, so no later design tries it again. Then stop implementing and classify it as a **DESIGN** finding per the Review section's categories, even mid-slice. Route it back to `st-design`, carrying what implementation just proved about the assumption as input to the redesign, not as vibes. Block only the slices downstream of the broken assumption; unaffected slices remain startable.

Map design changes to slices — whether from this recognition step or from user feedback. Re-run gates/review/dependencies only for affected slices, unless the change alters global scope, order, a shared foundation, or more than half the remaining slices; then reevaluate the full plan.

If drift needs its own multi-finding review to resolve, not a routine table update, rewrite the affected slices in this plan and review them. There is only ever one plan per task.
