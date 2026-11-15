---
name: st-crit
description: Expert review of a spec, a tech design, a bug diagnosis, or code, against what the work is supposed to do. Makes the strongest case for the work, then finds where it fails. Reports only what matters, and ends with a clear verdict: READY or CHANGES NEEDED.
---

Review work the way the most knowledgeable senior expert for it would review a colleague's: check it against what it is supposed to do, report only what matters, and say clearly whether it is ready. `.steel-thread/framework/reviews.md` defines a finding, its severities, the verdict, and how later passes work; follow it.

Run the review in a fresh context, as Reviewer Context in `reviews.md` says. Give the reviewer the work being reviewed, the task's spec, the objective (`docs/PRD.md`'s sections above its first feature), `docs/CONTEXT.md` (or the files they point to), and the code the work touches. On a later pass, give them the findings table and what changed since the last pass instead of the whole work.

Used where `.steel-thread/framework/development.md` calls for it — a spec's review, a bug diagnosis at Complex rigor or one a failing test doesn't prove, and the diff review before every Simple and Complex task is finished — and whenever the customer asks. The customer sees the verdict and resolutions, not the process.

## Step 1 — Identify the expert

Read the objective, CONTEXT.md, and `docs/engineering/ARCHITECTURE.md` to understand the product, its users, and its stack. Determine who the most critical expert would be:

- Spec → a product manager who has shipped this kind of feature, and asks whether the rules say what users need, clearly enough to build and test
- Tech design → a principal macOS engineer (Swift 6, SwiftUI, AppKit menu bar apps), who keeps it simple, checks it would actually work, and pushes back on scope the spec does not need
- Bug diagnosis → a debugging expert, who asks "how do you know that's the cause?" and wants the evidence
- Code → a senior reviewer for this stack, who reads the whole diff against its base, with its spec and design, for correctness, tests that prove behavior, and whether it follows the patterns the surrounding code uses

## Step 2 — Strongest case

Before looking for failures, make the strongest possible case FOR the work. What is it doing well? What assumptions are reasonable? What would make this genuinely good?

This is not flattery. It is understanding the work deeply enough to critique it meaningfully. A reviewer who can't make the strongest case for the work hasn't understood it.

## Step 3 — Check it against what it's supposed to do

Find where the work fails the standard in `reviews.md`: a spec rule or limit, a promise in CONTRACTS.md, a project rule, or a real bug with the steps that trigger it. Look hard, but only there. Ask:

- Does it do what each spec rule says, including its limits and edge cases?
- Does it break a promise other code, systems, or users' files rely on?
- Does it follow the patterns the surrounding code uses, the boundaries in ARCHITECTURE.md, and Active decisions? A departure needs a stated reason.
- Where does it crash, lose data, or give a wrong answer, and what steps get it there?
- Do the tests prove the behavior, or would they pass if it were broken?
- For a bug diagnosis: does the cause explain every symptom?

Do not look for what the work could also do. An extra case, option, or guard the spec doesn't ask for is not a finding. If you would argue for one anyway, list it as an IDEA, at most three.

## Step 4 — Severity and verdict

Give each finding a severity from `reviews.md`: BLOCKER, MAJOR, MINOR, or QUESTION. Then give the verdict:

- **READY** — no BLOCKER, MAJOR, or QUESTION is open. Say what you checked, so the customer can tell a clean review from a shallow one.
- **CHANGES NEEDED** — list the findings that stop it.

## Step 5 — Resolutions

For every finding, propose the smallest move that resolves it:

- A specific revision to make
- A new task, added with the st-tasks skill
- A question to answer before proceeding
- A risk to accept explicitly. Log it in `docs/DECISIONS.md` if it affects future work, along with any finding rejected on principle, so later reviews don't raise it again

Never just flag problems. The customer should finish reading the review knowing exactly what to do, not just what is wrong. List any ideas last, one line each, without resolutions: they are not part of this work.
