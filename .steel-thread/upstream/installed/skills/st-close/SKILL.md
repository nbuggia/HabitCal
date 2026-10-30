---
name: st-close
description: Close a task once its code is finished and validated against its spec. Moves everything that lasts out of the task's planning docs into tests, the engineering docs, the PRD, BACKLOG.md, and DECISIONS.md, and records where each piece landed. Use when a task's code is done, or a task with a work entry was marked done without being closed.
---

# Close a Task

This is step 6 of `.steel-thread/framework/development.md`. Close a task as soon as its code is finished, validated against its spec, and its diff reviewed, by the st-verify skill. If any of that hasn't happened yet, do it first with st-verify. **Skip when:** the task is Trivial, or has no work entry.

**Produces:** `close.md` in the work entry, which marks it closed. The folder stays in `docs/work/` as history.

The close moves everything that lasts out of the planning docs, and records where each piece landed. A task with a work entry is not done until it is closed. Read `.steel-thread/framework/docs-layout.md` first: it says what each lasting document holds.

The close is never heavier than the task. At Simple rigor it is usually a few rows, the spec's rules and their tests: do steps 1–4 and 6, and check the rows by eye instead of running step 5's searches. At Complex rigor, do every step.

## 1. List what has to last

Read every document in the work entry. List every rule in `spec.md` (new, changed, and `SHALL CONTINUE TO`, plus its limits, edge cases, and contracts), the spec's summary, users, Not Doing, and success criteria, its deferred use cases, every row in the design's Lasting Changes, and the chosen decisions of a prototype or spike.

Then list each place the build drifted from the design. Read it from the task's commits (`git log --grep T-NNN`), and from the slicing plan's Checkpoint Log and Design Drift if there is one. A slice with no commit citing the task has lost its evidence; tell the customer.

## 2. Apply them

Every item lands in a lasting document, or is dropped with the customer's approval. Most are in place once the tests and code are done; check rather than assume.

| Content | Lasting home |
| --- | --- |
| Spec: summary, users, why it matters | PRD feature section |
| Spec: Not Doing | PRD feature section's Not Doing |
| Spec: behavior rules and use cases | Behavior-named tests; a code comment where the behavior surprises |
| Spec: behavior automation can't reach | A manual test |
| Spec: UI sizes, states, wording | The UI code; UI tests for the states that matter |
| Spec: limits | A named constant with a comment, and a test at the edge |
| Spec: edge cases and errors | Tests; the general approach in CONVENTIONS.md |
| Spec: external contracts | CONTRACTS.md, and contract tests |
| Spec: success criteria | PRD feature section's Done Means |
| Spec: deferred use cases | BACKLOG.md, with this task as Source |
| Design: structure, boundaries, formats | ARCHITECTURE.md |
| Design: new practices | CONVENTIONS.md, or the convention skill for their area |
| Design: rejected alternatives likely to be proposed again | DECISIONS.md |
| Design: traps found during implementation | COMMON-FAILURE-MODES.md |
| Drift: changes what is there, such as a component or boundary | ARCHITECTURE.md, describing what was built |
| Drift: a choice someone reading the code might undo | A code comment where the choice was made |
| Drift: sets a practice later changes should follow | CONVENTIONS.md, or the convention skill for its area |
| Drift: rejects an alternative likely to be proposed again | DECISIONS.md |
| Other drift, and evidence: tests added, results | Commit messages; close.md without version control |
| Prototype: chosen UI decisions | UI code and UI tests |
| Spike: result | DECISIONS.md or COMMON-FAILURE-MODES.md |

- A rule is covered by a test whose name states it; the design's Test Points or Testing Strategy says which one. Rename a test whose name doesn't.
- The design's Lasting Changes go in the documents they name, describing what was actually built.
- A rejected alternative gets a DECISIONS.md entry only if it meets the bar in `.steel-thread/framework/files/decisions.md`.
- Create what doesn't exist yet: CONTRACTS.md from st-dev-setup's `contracts-template.md`, and the feature's PRD section in the format `.steel-thread/framework/files/prd.md` gives.
- If this task repeated a multi-step change an earlier task also made, such as wiring a new setting through every layer, propose a recipe for it: a convention skill from st-dev-setup's `convention-skill-template.md`, listed in CONVENTIONS.md.

## 3. Get one approval

The engineering docs, tests, and code are yours to update. The PRD, BACKLOG.md, and DECISIONS.md are the customer's: propose all of this task's changes to them, and any new convention skill, in one message. A rule is dropped only with the customer's approval.

## 4. Write close.md

Write `close.md` in the work entry: one row for each item from the list, naming where it landed. A test name, a file and heading, or an ID; never a path into `docs/work/`. A dropped item says so, with the reason. A task with nothing to keep says "No lasting changes." in place of the table.

```markdown
# Close: T-014 Autosync at launch

| Item | Landed in |
| --- | --- |
| Rule: sync starts within 5 seconds of launch | Test `syncs within five seconds of launch` |
| Rule: sync state shows in the menu bar | docs/manual-tests/sync.md, "Menu bar status" |
| Contract: on-device filename format | docs/engineering/CONTRACTS.md, "Device filenames" |
| Lasting Change: SyncScheduler owns sync timing | docs/engineering/ARCHITECTURE.md, "Sync" |
| Rejected: background fetch API | D-031 |
| Drift: reused StatusItem instead of a new menu bar view | Comment in `MenuBar.swift`, `showSyncState()` |
| Intent and success criteria | docs/PRD.md, "Sync" |
| Deferred: sync over cellular | BACKLOG.md |
| Rule: retry banner after three failures | Dropped: the customer chose silent retries |
```

## 5. Check it

Fix what these find, then run them again.

- **Trace check:** every item from the list has a row, and every row's target exists. Search the tests for each test name, find each heading in its file, and find each ID.
- **No-link check:** search the project, outside `docs/work/`, `.steel-thread/`, and the agent's skills folder, for `docs/work` and this entry's folder name. Code, tests, lasting documents, and TASKS.md cite a task ID, D-NNN, FM-NNN, or commit instead.

If your agent can start a subagent, you can also run a fresh-context review with the st-crit skill: given only the lasting documents and the code, can an agent make the next change in this area and tell intended behavior from accidental? It adds confidence but never decides the close, because an agent without a subagent would be grading its own work.

## 6. Finish

Leave the work entry where it is; `close.md` marks it closed. Mark the task done with the st-tasks skill, citing the task's last code commit, if the project uses version control, and the D- and FM- IDs the task added. Then commit the close: close.md, the lasting documents, and TASKS.md (Commits in development.md). Tell the customer in a few lines what landed where, anything dropped, and what went to BACKLOG.md. Then use the st-whats-next skill to recommend the next task.
