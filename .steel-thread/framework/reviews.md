# Steel Thread Reviews

How every review runs and how its findings are settled: the st-crit skill's reviews, st-design's review passes, and st-slice's. The skill that runs a review says who the reviewer is and what they get; this file holds what they share. Read it before you run a review or act on its findings.

A review works like a code review between two senior engineers: the reviewer checks the work against what it is supposed to do, the author fixes what is actually wrong, and the reviewer checks the fixes until it can say the work is ready. It is not a search for everything the work could also do.

## Reviewer Context

Run each review in a fresh context, so it judges what the work says, not your explanation of it. If your agent can start a subagent, give it only what the calling skill lists and read-only access to the code: never the conversation history, or reasoning that isn't written into the work. If it cannot, review using only those, and set aside what this session said about intent.

## Findings

The standard is the task's spec, not everything the work could do. A finding names the one of these the work fails, with evidence from the work or the code:

- **A spec rule or limit** it doesn't meet.
- **A promise** in CONTRACTS.md it breaks: a file format, a public API, anything other systems or users' files rely on.
- **A project rule** it ignores: a boundary in ARCHITECTURE.md, an Active decision in DECISIONS.md, CONTEXT.md's never-do rules, or the pattern the surrounding code follows, departed from without a stated reason.
- **A real bug:** a crash, lost or corrupted data, or a wrong result, with the steps that trigger it. In a design, a claim about the code that isn't true counts.

A guard or check for a situation is a finding only if the reviewer can say how that situation happens in this product. "What if the file is empty?" with no way for it to become empty is not one.

A spec is the standard itself, so a spec review measures it against the objective, CONTEXT.md, and the use cases the spec names: a rule that is missing, ambiguous, or untestable for one of its use cases is a finding, and a new use case is an idea.

Anything else is not a finding: a preference, a style nit, a "consider", an extra case the spec doesn't ask for, or a guardrail for a situation that can't happen. Finding nothing is a legitimate result: a clean review says what it checked, so the customer can tell it from a shallow one.

| Severity | Meaning |
| --- | --- |
| BLOCKER | A fundamental flaw. Resolve it before the next step starts. |
| MAJOR | A significant way the work fails the standard. Fix it unless there is a recorded reason not to. |
| MINOR | A real but contained failure. Worth fixing; safe to proceed with. |
| QUESTION | The reviewer can't judge without an answer only the author or the customer has. |
| IDEA | Not a finding: something the reviewer would argue for that the spec doesn't ask for. At most three per review. Never blocks, and is never built in this task. |

## Verdict

Every pass ends with one of two verdicts:

- **READY** — no BLOCKER, MAJOR, or QUESTION is open. The next step can start: slicing, code, or finishing the task.
- **CHANGES NEEDED** — with the open findings that stop it.

## Deciding Findings

Decide each finding yourself and record why:

- **ACCEPT** — apply the smallest change that resolves it, everywhere in the work it affects, not just where it was raised. A fix that adds a case, an option, or a guard the finding didn't require is new scope, not a fix.
- **REJECT** — don't apply it, and record the reason. Reject a finding that doesn't name the spec rule, promise, project rule, or bug it fails, and record the reason as out of scope.
- **DEFER** — record it as an open question or follow-up. Propose a task with the st-tasks skill for each one that is real work.
- **CLEAN** — a pass that found nothing still gets a row naming the pass.

Ideas are not decided. Record them in the findings table with severity IDEA and leave them there: when the task finishes, the st-verify skill shows them to the customer in one line each, and only the ones they pick go to BACKLOG.md.

Escalate to the customer only the high-judgment ones (see `.steel-thread/framework/development.md`): a finding you want to reject while it is a BLOCKER, or one you would accept that expands scope, changes behavior users would notice, or makes a hard-to-reverse change to architecture, persistence, IPC, or security. Put them in one message, with your recommendation for each.

Keep rejected and deferred findings in the work's findings table while the task is open, so a later pass doesn't raise them again. When a finding or a requirement change makes earlier findings obsolete, delete them, so no reviewer treats them as live; the superseding finding restates whatever survives.

## Passes

- **Pass 1 is the full review** of the work.
- **Each later pass checks only the fixes.** Give the reviewer the findings table and what changed since the last pass: the diff of the fixes, or the revised sections of a document. It answers two questions: is each accepted finding resolved, and did a fix break something? It doesn't raise new findings on parts that didn't change, or reopen a settled finding without new evidence.
- **Run passes until the verdict is READY,** at most three in all. Fixes made after the last pass are never left unreviewed: if the third pass still finds open findings, stop rather than fixing and moving on.
- Number passes in order, and record the number in each finding's Source column: `Pass 1`, `Pass 2`, `Pass 3`, and `External 1`, `External 2`, … for feedback the customer brings back. That is what lets a retro compare what each pass found.
- If the third pass isn't READY, set the document, or only the slices it blocks, to `Blocked`, with the reason on a `Blocked:` line, and hand it to the customer rather than running another pass. Work that can't converge in three passes usually needs rework, not more review.
