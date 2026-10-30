---
name: st-tasks
description: Add, finish, block, reorder, and plan tasks and phases in docs/TASKS.md, keeping its format. Use whenever TASKS.md changes — another skill or the conversation produced work to track, a task finished or got blocked, a phase starts or ends — or when the customer asks to see, add, or reprioritize tasks.
---

TASKS.md is the project's plan: phases in order, and tasks in priority order within them. It lives at `docs/TASKS.md`. Every change to it goes through this skill, so the format stays exact for the session start and the other skills that read it. If it does not exist, create it from `.steel-thread/framework/templates/TASKS.md`.

## Format

```markdown
# Tasks

## Phase 1 — Data ✓ 2026-10-03
- [x] T-001 Import frost date table · high · done 2026-10-03

## Phase 2 — CLI
- [ ] T-002 Write planting window calculator · high
      Signature is in src/window.py; logic not started.
- [ ] T-003 Add --zip flag · medium
      Blocked: waiting on decision about non-US postal codes.
```

- A phase is a heading, `## Phase N — Name`. The current phase is the first one without a ✓.
- A task is one checkbox line, `- [ ] T-NNN Title · priority`, where priority is high, medium, or low. The current task is the first incomplete task in the current phase.
- Detail goes on lines indented under the task. A blocked task's reason goes on an indented line starting `Blocked:`.
- IDs are `T-` plus three digits. A new task takes the highest existing ID plus one. IDs are never reused or changed, so other files can cite a task by ID even after its title changes.

## Changes

Adding tasks and phases needs the customer's approval; ask in one line as the work comes up, never as a wrap-up list: "I noticed X needs doing — want me to add it?" Marking progress needs no approval.

- **Add a task:** put it in the phase it serves, in priority order: after the open tasks of the same or higher priority, before lower ones. A task belongs to exactly one phase. Before adding, check that no open task already covers it.
- **Start a task:** add or update its detail line with what is in progress.
- **Finish a task:** `- [x]`, with ` · done YYYY-MM-DD` appended. Replace a detail line that described work in progress with nothing, or with what the task produced: the task's last code commit, if the project uses version control, and any D- and FM- IDs it added. Never a path into `docs/work/`.
  - A task that has a work entry (`docs/work/T-NNN-*/`) is finished only once it is closed: the entry holds a `close.md`. If it hasn't, close it first with the st-close skill, which comes back here to finish the task.
  - A Trivial change (see Rigor Levels in development.md) needs no task; its commit is the record, so don't propose one. If it already has a task, that task is finished when its work is, as is any other task with no work entry.
- **Block a task:** it stays incomplete; add the `Blocked:` line saying what would unblock it. **Unblock:** remove that line, and say which decision or event cleared it.
- **Reprioritize:** change the priority tag or move the line within its phase. The customer can also reorder by editing the file; treat what they wrote as current.
- **Add a phase:** propose it from the objective or the work ahead, with a one-line purpose: "It sounds like the next phase is the 0.2 release — does that fit?" Give it tasks only when it starts. A phase is usually a product release, planned from `docs/BACKLOG.md` (see the st-spec skill); when a backlog row becomes a task, delete the row in the same change.
- **Finish a phase:** when every task in it is done, append ` ✓ YYYY-MM-DD` to its heading.

Never delete or move a task or phase between phases; the file is the full history. A task that no longer matters is marked done with a detail line saying it was dropped and why.

## Reading it back

When the customer asks to see the tasks, show the current phase and the next one, not the finished ones. Lead with what is in flight and what is blocked. If the list is long, tangled, or drifting from the objective, say so and offer to step back and prioritize it together.
