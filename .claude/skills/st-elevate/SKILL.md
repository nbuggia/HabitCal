---
name: st-elevate
description: Interview in rounds that resolves ambiguity before work begins, and stress-tests a plan, decision, or diagnosis before acting on it. Asks the few questions that let the agent answer the rest.
based-on: Matt Pocock, grill-with-docs, grill-me, and grilling (https://github.com/mattpocock/skills)
---

Gets the customer and you to a shared understanding before anyone acts. It does two jobs in one loop:
- **Clarify** — when the direction is vague, find out what the customer wants
- **Challenge** — once there is a plan, test whether it will get them there

A session can start in either one and move between them: clarifying turns up a plan to challenge, and challenging a plan turns up intent that was never pinned down. Used by the st-whats-next skill during setup, by any skill that needs intent clarified or a plan pressure-tested, and by the customer before a big call.

The goal is not to ask every question. It is to learn enough about what the customer values that you can answer the rest yourself — and to help the customer discover those values, which they usually can't name up front.

## Step 1 — Ground yourself

Read the objective (`docs/PRD.md`'s sections above its first feature), `docs/CONTEXT.md` (including its tenets, which settle questions before you ask them), and any active entries in `docs/DECISIONS.md` that touch the subject, if they exist.

If there is a plan — a proposed fix, a design, an approach, a call the customer is about to make — state it back in its strongest form: what it does, why it is a good idea, and the assumptions it rests on. Ask the customer to confirm this is the plan. Do not challenge a plan you have not stated correctly.

## Step 2 — Map the questions, ask the few that matter

Privately, map everything unresolved as a tree: each question has the questions that depend on its answer. Do not show the customer the tree. Answer what you can from defaults, conventions, the project files, and facts you can look up.

From what's left, pick the questions with the most leverage: the ones whose answers would let you answer many others yourself. These are usually about trade-offs and priorities — what matters more when two good things conflict, what the customer would give up, what failure would hurt most. Ask them through a concrete situation from this work rather than in the abstract: "If the export is accurate but takes a minute, is that acceptable?" teaches you more than "Do you value speed or accuracy?"

When challenging a plan, focus on the assumptions it rests on — the ones that would waste significant effort if wrong. A challenge is a specific way the plan could fail:
- An assumption that may be wrong
- A failure mode the plan does not handle
- A conflict with the objective, CONTEXT.md, or DECISIONS.md
- A simpler plan that gets the same result
- A part that does not serve the objective and could be cut

Before asking anything, apply the test: "If the customer answered X, would I do something meaningfully different than if they answered Y — and could I not work it out myself?" If not, don't ask.

## Step 3 — Ask in rounds

Ask the high-leverage questions whose prerequisites are settled together in one round, most consequential first, then wait for the customer's answers. A question that depends on another one still open belongs to a later round.

Format a round like this:

```
**Q1 — <question title>**: <the question, with the options if there are any; for a challenge, what happens if it is not addressed>

Recommended: <your recommended answer>

---

**Q2 — <question title>**: ...
```

Word each question so "yes" accepts your recommendation. The customer can answer the whole round by number: "1 yes, 2 no — here's why, 3 the second option."

## Step 4 — Name the tenets, answer the rest

After each round, look at what the answers have in common and name the tenets behind them — the principles the customer is applying, often without having said so: "From your answers, it sounds like: correctness beats speed, and nothing ships without a way to undo it." Ask the customer to confirm or correct them. Naming tenets is how the customer discovers them; expect them to sharpen across rounds.

Then use the tenets and answers to resolve every question in the tree you now can. Show those resolutions briefly, each with the tenet or answer that decided it, so the customer can skim and override:

```
Settled from your answers:
- Retries: none, fail loudly — correctness beats speed
- Format: CSV only — Q2
```

Ask a new round only for what still can't be resolved.

## Keep the scope where it is

Recommendations must make the plan clearer, more likely to work, or smaller. Never recommend adding features, options, or polish the objective does not need. When a weakness can be fixed either by adding something or by cutting something, recommend the cut. If the subject is too big for one session, say so and propose splitting it before going further.

## Facts are yours, decisions are the customer's

If a question depends on a fact you can look up — a file, the code, documentation, a quick test — look it up instead of asking. If your agent can start a subagent, use one so the rest of the round is not blocked; otherwise look it up before asking the round. Only the questions that depend on that fact wait.

Never answer a decision for the customer that their answers and tenets don't settle. "I don't know" is a real answer: record it as an open question or a risk, and move on. If a question can't be settled by talking — how something should look or feel, whether an approach performs — stop and propose a quick experiment or prototype as a task instead.

## Maintain vocabulary as you go

As terms are resolved, propose additions to the vocabulary in `docs/CONTEXT.md`:
"We just defined X as Y — want me to add that to the project context?"
One-tap approval. Do not wait until the end.

## Step 5 — Close

The session is done when you can answer every remaining question in the tree yourself. Summarize:
- The tenets
- The shared understanding, or the plan as it now stands and what changed from step 1
- What you settled on the customer's behalf, and which tenet or answer decided it
- Risks the customer chose to accept
- Open questions that still need an answer

Ask the customer to confirm this is the shared understanding. Do not act on it until they do.

Then propose, one at a time:
- Tenets for `docs/CONTEXT.md`, only those that apply beyond the work at hand
- Decisions worth logging in `docs/DECISIONS.md`, including accepted risks
- Tasks, added with the st-tasks skill: experiments, open questions, and the work itself

When st-elevate was called by another skill, return the confirmed understanding and tenets to that skill instead of proposing tasks for the work itself.
