---
name: [feature name]
task: T-NNN
status: Draft / Approved / Blocked
last updated: YYYY-MM-DD
---

# Spec: \[Feature Name\]

\[Status meanings: Draft — being written or changed. Approved — it passed review with no open decisions; the next step can start. Blocked — waiting on the customer; say why on a `Blocked:` line under the status.

Every spec has Summary, Current Behavior, and Behavior; a new feature also has Users, Not Doing, and Use Cases. Leave out any other section, heading and all, when it has nothing in it. Keep the framing thin and let Behavior carry the length.\]

## 1. Summary

\[Two or three sentences: what this task changes, who it is for, and what they get from it. A reader who stops here should know what changes and why. Becomes the feature's PRD section at close.\]

## 2. Users

- **For:** \[who consumes what this changes, and the situation they are in: people using the product, callers of an API, a developer typing a command, or code reading a file format\]
- **Core value:** \[the one thing this must do for them to be worth building, in one specific sentence. "Helps people write" is too vague; "a writer can hand an agent a draft and review its changes without losing their own edits" is specific.\]
- **Not for:** \[who this is deliberately not built for\]

## 3. Not Doing

\[Every item needs a reason. Rejected ideas without one get suggested again. Something that may come later goes in Deferred instead.\]

- \[Excluded capability\] — \[why it is excluded\]

## 4. Current Behavior

\[How the product behaves today in the area this task changes, rebuilt from the sources "Planning Docs Are Scaffolding" in `.steel-thread/framework/docs-layout.md` lists. Cite the source of each point. For a new feature: "New feature; nothing exists today."\]

- \[behavior\] — \[source: test name, file and heading, or D-NNN\]

## 5. UI

\[Optional. The visible decisions: layout, states, sizes, and wording that the rules refer to. If a prototype settled them, copy the decisions here.\]

## 6. Use Cases

| Use case | Journey | How to verify |
| --- | --- | --- |
| UC-1 \[short title\] | \[journey in one or two sentences\] | \[test or demo\] |

## 7. Behavior

\[The delta. Number rules within this spec so the design and the close can refer to them; the numbers are never cited outside this task. Each rule should read as a test name.

- A rule with a trigger: `WHEN <condition> THE SYSTEM SHALL <behavior>`.
- When the outcome depends on state, use a table instead of a list of rules.
- When rules are checked in order, say so.
- Under any rule whose reason is not obvious, add a `Why:` line. A rule that settled an open question always gets one. At close, a reason that isn't obvious from the code becomes a code comment.\]

### New

B.1 WHEN \[condition\] THE SYSTEM SHALL \[behavior\].

### Changed

B.2 WHEN \[condition\] THE SYSTEM SHALL \[new behavior\]. Was: \[old behavior, and its source\]. Why: \[the reason\]

### Unchanged

\[What this task must not break. Name the existing test or manual test that already covers each one.\]

B.3 THE SYSTEM SHALL CONTINUE TO \[behavior\]. Covered by: \[test name\]

### Removed

\[Optional. Behavior this task takes away, with its source and why.\]

## 8. Limits

\[Numbers, sizes, timings, and invariants: what must always or never be true. Each one is checkable, and becomes a named constant and a test at its edge.\]

- \[Name\]: \[value or invariant\]

## 9. Edge Cases and Errors

\[Empty, failure, and boundary states, written as rules. Check st-spec's edge-case list: loading, cancelling, permission denied, offline, timeouts, races, several instances, stale data, focus loss, keyboard and accessibility, and neighboring features.\]

E.1 WHEN \[condition\] THE SYSTEM SHALL \[behavior\].

## 10. Contracts

\[Optional. External contracts this task adds or changes: file formats, filenames other systems read, URL schemes, public APIs, update feeds. Each goes in CONTRACTS.md at close.\]

- \[Contract\]: \[the promise, and who relies on it\]

## 11. Success Criteria

\[Optional. Measurable results that do not depend on the technology, such as "a first-time user finishes setup in under two minutes." Becomes the PRD feature section's Done Means.\]

## 12. Deferred

\[Use cases and ideas that wait. Each becomes a BACKLOG.md row at close, with this task as its Source. Rows may stay rough.\]

- \[feature\] — \[why it waits\]

## 13. Assumptions

\[Optional. Defaults chosen where the customer didn't say, so they can be challenged. Include what the spec assumes in place of a prototype the customer declined.\]

## 14. Open Questions

\[Only unanswered questions. Mark each one inline where it applies as `[NEEDS DECISION: …]` and list it here, with what will answer it: the customer, or a prototype. When one is answered, move the answer into the rules with a `Why:` line, and delete it from this list.\]

- \[question\] — \[rule or section it blocks\] — \[who or what answers it\]
