# docs/PRD.md — Format and Rules

The PRD holds the product's intent: why it exists, what done means, and for each feature area, who it is for and why it matters. Its sections above the first feature are the project's objective: short enough to read at every session start, and changed rarely.

## Format

```markdown
# Product: Markymark

## Outcome
## Done Means
## Not Doing
## Constraints

## Feature: Sync

**For:** writers who edit the same vault on two machines.
**Why it matters:** they never merge two versions of a note by hand.

## Not Doing
- Real-time co-editing — one writer per vault.

## Done Means
- A note edited offline appears on the other machine within a minute of reconnecting.

## Flows
- Spans Search: a synced note is searchable as soon as it lands.
```

- **Outcome** — one paragraph: what the product does, for whom, and why it matters.
- **Done Means** — testable criteria, not activities. "A writer's edit on one machine appears on the other within a minute," not "build sync."
- **Not Doing** — at least two things that are explicitly out of scope, and why. An objective with nothing out of scope has not been scoped.
- **Constraints** — deadlines, platforms, budgets, anything that cannot change. Leave it out if there are none.
- One `## Feature:` section per product area, named the way the product names it. Feature sections are read on demand, when work touches the area.
- **Flows** lists behavior that spans features, and names the other feature. Leave out any subsection with nothing in it.
- The PRD holds intent, not behavior rules. Rules live in tests, manual tests, and CONTRACTS.md (see `.steel-thread/framework/docs-layout.md`).

## Creating and changing it

The st-whats-next skill writes the objective during setup, from `.steel-thread/framework/templates/PRD.md`. The close (the st-close skill) adds a feature section the first time a task adds a feature.

- Change the objective when the customer changes direction, scope, or what done means. Every change to it also gets a DECISIONS.md entry recording what changed and why.
- Feature sections change when a task closes, approved with the rest of that task's changes to the customer's files. They need a DECISIONS.md entry only when the change meets DECISIONS.md's bar.
- An older install may have `docs/OBJECTIVE.md`. Propose moving its sections into the PRD, and delete it in the same approved change.

## When the PRD already exists elsewhere

Before offering to write an objective, look for one the project already has, and use the first that exists: `PRD.md`, `.claude/PRD.md`, `.kiro/steering/product.md`, then `OBJECTIVE.md` at the project root. Match file names in any case.

If you find one, write `docs/PRD.md` as a pointer to it, and tell the customer in one line: "Using PRD.md as this project's objective." Don't interview to fill in sections it lacks. Feature sections go in the file it points to.

```markdown
# Product

This project's PRD lives in `PRD.md`. Read that instead.
```

## When the customer skips the objective

If no objective exists and the customer declines to write one, or doesn't take up the offer in the session it was made, write the PRD in the skipped form. Then never offer it again; the customer can ask for it. Feature sections still go below it.

```markdown
# Product: Markymark

Objective not set. The customer chose not to write one (YYYY-MM-DD). Don't offer it again.
```

When they later ask for one, replace that line with the objective's sections. Pointer and skipped forms need no DECISIONS.md entry.
