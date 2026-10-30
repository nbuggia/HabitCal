---
name: st-whats-next
description: Recommend the single most valuable next step and give the customer what they need to start it. Sets up a new project one step at a time (objective, context, stack, phases), and for an established project rebuilds where they left off and what to do next. Use when starting or resuming work, or when the customer asks what's next.
---

One job: recommend the single most valuable next step, and give the customer everything they need to start it right away. One recommendation, not a menu. Offer at most one alternative, and only when it is a real contender.

The customer's files live in `docs/`: PRD.md, CONTEXT.md, TASKS.md, BACKLOG.md, and DECISIONS.md. Steel Thread's working files live in `.steel-thread/`. Starter files are in `.steel-thread/framework/templates/`, and the format and rules for each are in `.steel-thread/framework/files/` — read a file's rules before writing it.

## Step 1 — Read the state

Start from what the Session Start Protocol in `.steel-thread/framework/steel-thread.md` reads, and read whatever of it this session hasn't yet. Never ask the customer for something these files already answer.

If there is no objective or no CONTEXT.md, first look for one the project already has, as `files/prd.md` and `files/context.md` describe, and point to it.

Also list `docs/work/`. A task marked done whose folder has no `close.md` was never closed.

Then find the first row that matches. A skipped objective counts as done, unless the customer asked for one:

| State | Next step |
| --- | --- |
| No objective | Setup: create the objective |
| No CONTEXT.md | Setup: capture context |
| No `docs/engineering/ARCHITECTURE.md` | Setup: tailor development |
| TASKS.md has no phases | Setup: plan phases and first tasks |
| The customer says the direction has changed | Reframe |
| A task was marked done without being closed | Close the task |
| The current task's code is finished, and it has a work entry | Close the task |
| Open tasks in the current phase | Resume |
| Every task in the current phase is done | Close the phase |
| Every phase is done | Check against Done Means |

## Setup steps

A new project is set up one step at a time. Each step is a short conversation that produces one file. When a step is done, say what's next and offer to keep going: "The objective is written. Next is the project vocabulary — about five minutes. Keep going, or start working and do it later?"

In an existing project, read before you ask: the README, the docs, the code's structure, and recent version-control history. Draft each file from what they show, and interview only for what they can't answer — usually the outcome, done means, and not doing.

Use the st-elevate skill for every interview. Propose what you've captured before writing it: "Here's what I've got — does this look right before I write it?" One-tap approval. Never write placeholder text — if a section has nothing yet, leave it out.

### Create the objective

Say: "Let's set this project up. First: what is it for? I'll ask a few questions." If the customer would rather not, write the skipped form (see `files/prd.md`) and move to the next step.

Interview, in order:

1. **Outcome** — what does the product do, for whom, and why does it matter? Push for specificity. "A note-taking app" is not specific enough. "A Markdown editor that keeps one vault in sync across a writer's machines, with no server" is.
2. **Done means** — how will we know it's finished? Testable criteria, not activities.
3. **Not doing** — what is explicitly out of scope? Get at least two items. If the customer can't name any, the project isn't scoped yet — say so.
4. **Constraints** — deadlines, platforms, budgets, anything that cannot change.

Write `docs/PRD.md` from the template. Feature sections come later, as tasks close. At the same time, create whichever of these don't exist yet, from the templates: `docs/DECISIONS.md`, and in `.steel-thread/`, pickup.md and customizations.md. Never overwrite a file that exists.

If `docs/OBJECTIVE.md` exists from an older install, propose moving its sections into the PRD instead of interviewing (see `files/prd.md`).

Log any hard-to-reverse choice the interview surfaced in DECISIONS.md, with approval.

### Capture context

1. **Vocabulary** — what terms does the product's domain define? Which names should the code and the conversation share? What would someone get wrong without context, and what aliases should be avoided?
2. **Never do** — what should the agent never do on this project? What would be a serious mistake: a branch to never push to, data to never touch, a command to never run?

Write `docs/CONTEXT.md` from the template. For a small project, the customer may skip this — then write CONTEXT.md with just a Vocabulary heading, so this step isn't offered again, and fill it in as terms come up.

### Tailor development

Use the st-dev-setup skill. It learns the stack from the code, or from the objective's constraints for a new project, writes the engineering docs, and adapts the development process to the stack. Say why before starting: "This is a Tauri app, so I'll fit the design and test process to Rust, the WebView, and your targets. About ten minutes, mostly reading code."

### Plan phases and first tasks

Propose phases based on the objective: typically one phase per release of the product, each ending in something users can run. The first tasks are usually the first release's features, each starting with a spec (see `.steel-thread/framework/development.md`).

"Based on the objective, I'd suggest three releases — [names]. Does that feel right, or should we adjust?"

Then propose the first few tasks for the first phase only. Later phases get tasks when they start. Write what the customer approves with the st-tasks skill.

When setup is complete, go straight to Resume and recommend the first task.

## Reframe

When the customer says the direction, scope, or definition of done has changed:

- Run the objective interview again, focused on what changed — not what you already know
- Propose edits to the objective rather than rewriting it
- Log the change in DECISIONS.md, superseding earlier decisions it overturns
- Do not reset TASKS.md. Propose new phases or tasks the new direction needs, through the st-tasks skill, and flag open tasks that no longer serve the objective
- Then continue with Resume

## Resume

This is the moment the customer would otherwise spend reconstructing where they were. Do that work for them.

### Rebuild where they left off

1. Start from pickup.md's In Flight and Suggested Start, and the current task in TASKS.md with its detail lines.
2. Read the Active decisions that touch that task.
3. Open the actual files the in-flight work lives in. Check that their state matches the pickup note. Files may have changed outside the session — if version control is available, check what changed since the date on the pickup note.
4. If the note and the files disagree, trust the files and say so: "The pickup note says calculate_window() has no logic, but it's half written — the frost offset is done, the crop lookup isn't."

### Choose the next step

Default to the current task: the first incomplete task in the current phase. Recommend something else only when it is clearly better, and say why in one sentence:

- **Work is half done** — finishing it beats starting something new
- **A blocker can be cleared now** — if a decision would unblock a task and the objective or existing decisions already point to the answer, propose making it
- **Something higher priority is unblocked** — a high task further down that is now workable
- **The task list has stopped making sense** — if it is long, tangled, or drifting from the objective, recommend stepping back to reprioritize instead

### Present it

Keep it short enough to read in thirty seconds. Use this shape, leaving out any line with nothing in it:

"**Where you left off:** T-002 Write planting window calculator.
**Done so far:** the frost offset — `calculate_window()` in src/window.py returns the right start date.
**Still to do:** the crop lookup, and the end of the window.
**Keep in mind:** D-002 — US zip codes only. Open question from last time: should the window clip at the first fall frost?
**Next step:** add the crop lookup table to src/window.py. That's the smallest piece that gets a real answer out of the function.

Want to start there?"

The next step must be concrete and small enough to start immediately — a specific file, function, section, or question. Not "continue working on T-002."

## Close the task

A task's code is finished, or a task was marked done without being closed. Say so in one line, "T-014's code is done, so the next step is closing it — moving what lasts into the tests and docs," and use the st-close skill. If the code hasn't been validated against its spec and its diff reviewed yet, do that first with the st-verify skill. Then come back to Choose the next step.

## Close the phase

Every task in the current phase is done.

- Summarize what the phase produced, in two or three lines
- Mark the phase complete with the st-tasks skill
- Propose the next phase. If `docs/BACKLOG.md` has Next rows, offer to plan the next release from them, with the st-spec skill. Otherwise propose the first few tasks for the next phase, with the st-tasks skill

## Check against Done Means

Every phase is done. Go through each Done Means criterion in the objective, or the success criteria of the file it points to, and say whether the work meets it, with evidence. If there are no criteria, summarize what the project produced instead. Then recommend one of: a new phase for what is missing, or calling the project done.

## After the recommendation

Update pickup.md with the recommendation as the Suggested Start. If the customer picks something else, that's their call — update pickup.md and help them start it.
