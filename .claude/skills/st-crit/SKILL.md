---
name: st-crit
description: Expert review of a spec, a tech design, a bug diagnosis, or code. Makes the strongest case for the work, then attacks it. Reports only what matters. Clear verdict.
---

Review work from the perspective of the most knowledgeable, most critical expert for it. Strongest case first, then attack. Report only what matters. Clear verdict.

Run the review in a fresh context, as Reviewer Context in `.steel-thread/framework/reviews.md` says, which also defines a finding and its severities. Give the reviewer the work being reviewed, the objective (`docs/PRD.md`'s sections above its first feature), `docs/CONTEXT.md` (or the files they point to), and the code the work touches.

Used where `.steel-thread/framework/development.md` calls for it — a spec's review, a bug diagnosis at Complex rigor or one a failing test doesn't prove, and the diff review before every Simple and Complex close — and whenever the customer asks. The customer sees the verdict and resolutions, not the process.

## Step 1 — Identify the expert

Read the objective, CONTEXT.md, and `docs/engineering/ARCHITECTURE.md` to understand the product, its users, and its stack. Determine who the most critical expert would be:

- Spec → a product manager who has shipped this kind of feature, and asks what users actually need and what the spec leaves unsaid
- Tech design → a principal engineer on this stack, who keeps it simple, finds the failure modes, and pushes back on scope the spec does not need
- Bug diagnosis → a debugging expert, who asks "how do you know that's the cause?" and wants the evidence
- Code → a senior reviewer for this stack, who reads the whole diff against its base, with its spec and design, for correctness, tests that prove behavior, and the project's conventions

## Step 2 — Strongest case

Before attacking, make the strongest possible case FOR the work. What is it doing well? What assumptions are reasonable? What would make this genuinely good?

This is not flattery. It is understanding the work deeply enough to critique it meaningfully. A reviewer who can't make the strongest case for the work hasn't understood it.

## Step 3 — Attack

Now become the domain expert and find what fails. Look hard, but report only findings as `reviews.md` defines them. Finding nothing is a legitimate result.

Ask:
- How does this fail?
- What assumptions are wrong?
- What has been missed entirely?
- What would this expert object to immediately?
- What looks fine now but causes real problems downstream?

Do not look for nitpicks. Look for things that matter. A root cause that doesn't explain every symptom. A design that breaks a contract. A test that passes without proving the behavior. A requirement that ignores a critical constraint.

## Step 4 — Severity and verdict

Give each finding a severity from `reviews.md`: BLOCKER, MAJOR, MINOR, or QUESTION.

Deliver a verdict:
- BLOCK — a BLOCKER must be resolved before proceeding
- CONCERNS — real issues worth addressing, can proceed with awareness
- CLEAN — nothing met the bar for a finding. Say what you checked, so the customer can tell a clean review from a shallow one

## Step 5 — Resolutions

For every finding, propose what to do about it:
- A specific revision to make
- A new task, added with the st-tasks skill
- A question to answer before proceeding
- A risk to accept explicitly. Log it in `docs/DECISIONS.md` if it affects future work, along with any finding rejected on principle, so later reviews don't raise it again

Never just flag problems. Always suggest the next move. The customer should finish reading the review knowing exactly what to do, not just what is wrong.
