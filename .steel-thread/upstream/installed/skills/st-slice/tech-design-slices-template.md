---
name: feature name slicing plan
task: T-NNN
design doc: [link]
design doc version/commit: [commit/version]
date created: YYYY-MM-DD
last updated: YYYY-MM-DD
status: Draft / Approved / Blocked
---

# Slicing Plan: Feature

## 0. Sliceability Gate

- Design conclusion: [verbatim]
- Design change required to slice: [none / change and reason]

## 1. Rejected Alternative

[Alternative decomposition and why rejected.]

## 2. Slices

Add only justified slices. A layer-only slice must name the later vertical slice
it enables.

### Slice N: Name

| Field               | Value                                                                        |
| ------------------- | ---------------------------------------------------------------------------- |
| Status              | Pending / Done / Blocked                                                     |
| Scope               | End-to-end outcome.                                                          |
| Demo criterion      | Runnable proof, or enabled later slice.                                      |
| Dependencies        | Concrete predecessor outputs consumed.                                       |
| Explicitly deferred | Adjacent excluded work.                                                      |
| Invalidation risk   | Assumptions, ceilings, and falsifying evidence.                              |
| Size justification  | Why this is one cohesive outcome.                                            |
| Test gate           | Failing tests first at the design's test points, then implement. N/A only with the reason. |

## 3. Review Findings

Severities and decisions: `.steel-thread/framework/reviews.md`.

| #   | Finding | Category                     | Severity                                                | Decision                | Slices | Rationale | Next step |
| --- | ------- | ---------------------------- | ------------------------------------------------------- | ----------------------- | ------ | --------- | --------- |
| 1   |         | SLICING / DESIGN / EXPANSION | BLOCKER / MAJOR / MINOR / QUESTION                      | ACCEPT / REJECT / DEFER |        |           |           |

## 4. Dependency Graph

[Ordered list or ASCII graph.]

## 5. Checkpoint Log

Required after every completed slice — a Done slice with no entry here means this was skipped, not that there was nothing to report. The evidence itself goes in the commit message.

### After Slice N

- Commit:
- Affected remaining slices reviewed:
- Changed:
- Unchanged and why:
- New conflicts:

## 6. Design Drift

| Change | Affected slices | Reevaluation |
| ------ | --------------- | ------------ |
