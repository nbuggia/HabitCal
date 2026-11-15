---
name: st-tasks
description: Add, start, block, finish, reorder, and plan tasks and phases in docs/TASKS.md, keeping its format. Use whenever TASKS.md changes — another skill or the conversation produced work to track, a task's status changed, a phase starts or ends — or when the customer asks to see, add, or reprioritize tasks.
---

TASKS.md is the project's plan: phases in order, and tasks in priority order within them. It lives at `docs/TASKS.md`. Every change to it goes through this skill, so the format stays exact for the session start and the other skills that read it. If it does not exist, create it from `.steel-thread/framework/templates/TASKS.md`.

## Format

```markdown
# Tasks

## Phase 1 — Data ✓ 2026-10-03

| ID | Task | Priority | Status | Notes |
| --- | --- | --- | --- | --- |
| T-001 | Import frost date table | high | done 2026-10-03 | a41c9e2 · D-002 |

## Phase 2 — CLI

| ID | Task | Priority | Status | Notes |
| --- | --- | --- | --- | --- |
| T-002 | Write planting window calculator | high | in progress | Frost offset done; crop lookup next. |
| T-004 | Print the window as a calendar | high | awaiting test 2026-10-09 | 2 checks in docs/manual-tests/next-pass.md |
| T-003 | Add --zip flag | medium | blocked | Waiting on a decision about non-US postal codes. |
| T-005 | Add --json output | low | open | |
```

- A phase is a heading, `## Phase N — Name`, followed by its table. The current phase is the first one without a ✓.
- Each task is one row, in priority order. Priority is high, medium, or low.
- IDs are `T-` plus three digits. A new task takes the highest existing ID plus one. IDs are never reused or changed, so other files can cite a task by ID even after its title changes.
- Notes are one short phrase. Anything longer belongs in the task's work entry. Never put a `|` in a cell; write `\|` if one is unavoidable.

### Status

Status is exactly one of these values:

| Status | Meaning | Notes hold |
| --- | --- | --- |
| `open` | Not started | Nothing, or what it needs first |
| `in progress` | Being worked on | What is in progress, such as the slice |
| `blocked` | Can't move until the customer decides or supplies something | What would unblock it |
| `awaiting test YYYY-MM-DD` | Code done, reviewed, and its Lasting Changes applied; only checks left for the customer's test pass remain. The date is when it started waiting. | How many checks, in `docs/manual-tests/next-pass.md` |
| `done YYYY-MM-DD` | Finished | The task's last code commit, if the project uses version control, and any D- and FM- IDs it added. Never a path into `docs/work/`. |
| `dropped YYYY-MM-DD` | No longer matters | Why |

The current task is the first row in the current phase that is `in progress`, or else the first that is `open`. Blocked and awaiting-test tasks are skipped: neither has work the agent can do.

## Changes

Adding tasks and phases needs the customer's approval; ask in one line as the work comes up, never as a wrap-up list: "I noticed X needs doing — want me to add it?" Changing a task's status or Notes needs no approval.

- **Add a task:** add its row to the phase it serves, in priority order: after the open tasks of the same or higher priority, before lower ones, with status `open`. A task belongs to exactly one phase. Before adding, check that no unfinished task already covers it.
- **Start a task:** set it to `in progress`, with what is in progress in Notes. Keep the very next step there as the work moves, since it is what a returning session resumes from.
- **Block a task:** set it to `blocked`, with what would unblock it in Notes. **Unblock:** set it back to `open` or `in progress`, and say which decision or event cleared it.
- **Wait for a test pass:** set it to `awaiting test` with today's date, when the st-verify skill leaves checks for the customer's test pass.
- **Finish a task:** set it to `done` with today's date, and replace Notes with what the task produced.
  - A task that has a work entry (`docs/work/T-NNN-*/`) is finished only once its design's Lasting Changes are applied and its test-pass checks have passed. If they haven't, use the st-verify skill first, which comes back here.
  - A Trivial change (see Rigor Levels in development.md) needs no task; its commit is the record, so don't propose one. If it already has a task, that task is finished when its work is, as is any other task with no work entry.
- **Drop a task:** set it to `dropped` with today's date, and say why in Notes.
- **Reprioritize:** change the priority or move the row within its phase. The customer can also reorder by editing the file; treat what they wrote as current.
- **Add a phase:** propose it from the objective or the work ahead, with a one-line purpose: "It sounds like the next phase is the 0.2 release — does that fit?" Give it tasks only when it starts. A phase is usually a product release, planned from `docs/BACKLOG.md` (see the st-spec skill); when a backlog row becomes a task, delete the row in the same change.
- **Finish a phase:** when every task in it is `done` or `dropped`, append ` ✓ YYYY-MM-DD` to its heading. A task awaiting test keeps its phase open.

Never delete a row or move a task between phases; the file is the full history.

## Older Format

Before this format, tasks were checkbox lines (`- [ ] T-NNN Title · priority`) with indented detail lines. If TASKS.md still uses them, convert it before your first change, and show the customer the result for approval, since it is their file:

- `- [x] … · done YYYY-MM-DD` becomes `done YYYY-MM-DD`, or `dropped YYYY-MM-DD` if its detail line says it was dropped.
- `- [ ]` with a `Blocked:` line becomes `blocked`; with a detail line describing work under way, `in progress`; otherwise `open`. A detail line that says the code is done and only the customer's tests are left becomes `awaiting test`, with its checks added to `docs/manual-tests/next-pass.md` (see the st-verify skill).
- Detail lines become Notes, shortened to one phrase.

## Reading It Back

When the customer asks to see the tasks, show the current phase and the next one, not the finished ones. Lead with what is in progress, blocked, and awaiting test. If the list is long, tangled, or drifting from the objective, say so and offer to step back and prioritize it together.
