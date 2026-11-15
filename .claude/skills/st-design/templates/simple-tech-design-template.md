---
task: T-NNN
rigor: Simple
status: Draft / Approved / Blocked
date created: YYYY-MM-DD
---

# Tech Design: Bug or Feature Name

\[Keep this under \~40 lines. If it needs more, or any Complex trigger in `.steel-thread/framework/development.md` applies, re-size the task and rewrite this from the Complex template.\]

## Summary

\[What changes and why, in three to five lines. For a bug: the symptom, the root cause and its evidence, and the reproducing test. Include the settled scope.\]

## Approach

\[The files and functions the change touches, and the existing code whose pattern it follows, by file. For any departure from that pattern, one line on why. If the pattern itself is wrong, say so and whether this change fixes it. If it takes two slices, name them in one line each.\]

## Test Points

| Test (named for the behavior it proves) | Kind (unit / integration / UI / manual) | Spec rules proved |
| --- | --- | --- |
|  |  |  |

## Risks

\[Only the failure modes from COMMON-FAILURE-MODES.md that apply, and how the change handles each. Remove this section if none apply.\]

## Lasting Changes

\[What this change adds to the lasting documents. st-verify applies these when the task is finished; anything not listed is lost then. Write "None." when it adds nothing.\]

| Change | Goes to |
| --- | --- |
|  | ARCHITECTURE.md / CONTRACTS.md / COMMON-FAILURE-MODES.md / DECISIONS.md / PRD.md / BACKLOG.md |
