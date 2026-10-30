# docs/BACKLOG.md — Format and Rules

BACKLOG.md holds the features the product may get later: deferred use cases, follow-up ideas, and requests that aren't committed work yet. Committed work is in TASKS.md. It is not read at session start, only when planning a release or closing a phase.

## Format

```markdown
# Backlog

| Feature | Release | Why | Source |
| --- | --- | --- | --- |
| Search inside closed files | Next | Search stops at open files today | T-031 |
| Vault-wide replace | Next | Most-requested after search | customer |
| Export to PDF | Later | Beta users share drafts as PDF | customer |
```

- **Release** is `Next` or `Later`. Next rows come first; Later rows are in no order.
- **Source** is the task that deferred the feature, or `customer`. It keeps a deferred requirement from quietly disappearing.

## Rules

- It is the customer's file: change it only with their approval. New rows go in as Later unless the customer says Next.
- "Maybe later" belongs here; "never" belongs in the PRD's Not Doing, for the product or the feature.
- When a feature becomes tasks in TASKS.md, delete its row. Rows are never marked done in place.
- Create it from `.steel-thread/framework/templates/BACKLOG.md` the first time a row is added.
