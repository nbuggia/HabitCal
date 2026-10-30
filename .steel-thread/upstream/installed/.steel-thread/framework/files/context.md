# docs/CONTEXT.md — Format and Rules

CONTEXT.md holds the standing rules for how to work on this project.

## What belongs in it

- **Vocabulary** — defined terms and aliases to avoid. This is the most important section. When a term is defined here, use it precisely everywhere.
- **Tenets** — the principles the customer applies when good options conflict: "Correctness beats speed." They let you settle questions the customer would otherwise have to answer. Tenets are discovered through the st-elevate skill, not asked for up front. A tenet is a principle for settling future choices; one specific choice is a decision, and goes in DECISIONS.md.
- **What the agent should never do** — explicit constraints. These are absolute.

What the project is for belongs in the PRD. How the code is built belongs in `docs/engineering/` (see `.steel-thread/framework/docs-layout.md`). Why a rule exists belongs in DECISIONS.md.

## When context already exists elsewhere

If the project root has a `CONTEXT.md`, write CONTEXT.md as a pointer to it, the same way as the PRD, instead of capturing context again.

## When to update it

- When a new term is used that isn't defined
- When a new constraint is agreed — log the decision behind it in DECISIONS.md if it is hard to reverse
- When an st-elevate session surfaces a tenet that applies beyond the work at hand
