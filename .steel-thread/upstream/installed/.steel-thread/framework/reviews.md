# Steel Thread Reviews

How every review runs and how its findings are settled: the st-crit skill's reviews, st-design's review passes, and st-slice's. The skill that runs a review says who the reviewer is, what they get, and how many passes it has; this file holds what they share. Read it before you run a review or act on its findings.

## Reviewer Context

Run each review in a fresh context, so it judges what the work says, not your explanation of it. If your agent can start a subagent, give it only what the calling skill lists and read-only access to the code: never the conversation history, or reasoning that isn't written into the work. If it cannot, review using only those, and set aside what this session said about intent.

## Findings

A finding is a concrete way the work fails, with evidence from the work or the code. A preference, a style nit, or a "consider" is not a finding; leave it out. Finding nothing is a legitimate result: a clean review says what it checked, so the customer can tell it from a shallow one.

| Severity | Meaning |
| --- | --- |
| BLOCKER | A fundamental flaw. Resolve it before the next step starts. |
| MAJOR | A significant way the work fails. Fix it unless there is a recorded reason not to. |
| MINOR | A real but contained failure. Worth fixing; safe to proceed with. |
| QUESTION | The reviewer can't judge without an answer only the author or the customer has. |

## Deciding Findings

Decide each finding yourself and record why:

- **ACCEPT** — apply it, everywhere in the work it affects, not just where it was raised.
- **REJECT** — don't apply it, and record the reason. Reject a finding that adds work without naming a requirement the work fails without it, and record the reason as out of scope.
- **DEFER** — record it as an open question or follow-up. Propose a task with the st-tasks skill for each one that is real work.
- **CLEAN** — a pass that found nothing still gets a row naming the pass.

Escalate to the customer only the high-judgment ones (see `.steel-thread/framework/development.md`): a finding you want to reject while it is a BLOCKER, or one you would accept that expands scope, changes behavior users would notice, or makes a hard-to-reverse change to architecture, persistence, IPC, or security. Put them in one message, with your recommendation for each.

Keep rejected and deferred findings in the work's findings table while the task is open, so a later pass doesn't raise them again. When a finding or a requirement change makes earlier findings obsolete, delete them, so no reviewer treats them as live; the superseding finding restates whatever survives.

## Passes

- The skill that runs the review sets its budget in passes.
- Number passes in order, and record the number in each finding's Source column: `Pass 1`, `Pass 2`, `Blocker verification`, and `External 1`, `External 2`, … for feedback the customer brings back. That is what lets a retro compare what each pass found.
- After the first full pass, a later pass checks only what changed and the earlier blockers. Don't reopen a settled finding without new evidence; a settled MAJOR, MINOR, or QUESTION never justifies another pass.
- If a BLOCKER is still open when the budget is spent, set the document, or only the slices it blocks, to `Blocked`, with the reason on a `Blocked:` line, and hand it to the customer rather than running another pass. Work that can't converge in its budget usually needs rework, not more review.
