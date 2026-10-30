# Steel Thread Development Process

How to take a feature or a bug from idea to tested code. Read this before you change code: its Rigor Levels section decides how much of the process the change needs, and each step names the skill that runs it. You do not need it for questions or reading code.

This process is written for any stack. The st-dev-setup skill tailors this project's copy, and the development skills, to its languages and platforms. If `docs/engineering/ARCHITECTURE.md` does not exist yet, run it before the first feature.

The flow is:

```
spec → prototype (optional) → tech design → slicing plan (complex designs only) → tests → code → close
```

Each step produces one document, and the next step reads it. Move through the steps on your own: a document's review is its gate, not the customer. When a step finishes, tell the customer in one line what it produced and keep going.

Stop for the customer only when the work is blocked, for one of two reasons:

- **A high-judgment decision.** The choice is hard to reverse, changes what users would notice in a way the spec does not settle, or trades off things the customer cares about with no clear winner. A choice you can make well from the spec, the code, and the project's conventions is not one of these; make it and record why.
- **Critical input.** Something only the customer can supply, such as a fact, an access, or an intent the spec leaves open, without which the next step would be a guess.

When you stop, ask one question, give your recommendation, and keep working on anything that does not depend on the answer.

Before you create a work entry, write a planning document, or close a task, read `.steel-thread/framework/docs-layout.md`: where each document goes, the states a planning document moves through, and which lasting document holds what.

A step is skipped only when the task's rigor level or the rules below say so. When you skip one, say which and why: "This is a Simple fix, so no slicing plan."

## Rigor Levels

**Every change gets a rigor level before work starts: Trivial, Simple, or Complex.** The level decides which steps run and how heavy each one is, so a one-line fix doesn't pay for a feature's process. Set it once, at the start of the task, and tell the customer in one line which criterion decided it: "This is Trivial: one comparison, and a failing test proves the fix."

Check the Trivial criteria first; they need no file reads. If the change isn't clearly Trivial, read `AGENTS.md`, `docs/engineering/ARCHITECTURE.md`, and `docs/engineering/CONTRACTS.md` before choosing between Simple and Complex.

| Rigor level | Criteria | Examples |
| --- | --- | --- |
| Trivial | All of these:<br>1. One local edit; nothing else depends on what it changes.<br>2. No promise changes, unless a bug fix restores one.<br>3. A mistake is visible on sight, or one test settles it. | A copy fix, a style value, a default. A wrong comparison in one function, with a failing test that reproduces the bug. |
| Simple | Anything that is not Trivial and hits no Complex trigger. | A save handler that skips a validation the other handlers apply. A new settings screen built from existing components and commands. |
| Complex | Any of these triggers:<br>1. **Not revertible:** it changes a persisted format or stored data, so reverting the commit can't undo it.<br>2. **Contract:** it adds or changes a promise in CONTRACTS.md, such as a file format, URL scheme, or public API.<br>3. **Structure:** it adds a component, a process or thread boundary, or a dependency, or moves a boundary in ARCHITECTURE.md.<br>4. **Risky ground:** it touches concurrency, security, or permissions.<br>5. **Not fully testable:** correctness depends on timing or on behavior invented as you go. | Adding a field to the persisted settings file. Builds already shipped wrote the old shape to disk, so reverting a commit can't undo it. |

- A close call is Simple. Choosing Complex names its trigger: "Complex: it adds a field to the settings file."
- Following an existing convention is a sign a change is Simple, not a requirement. In a new project, the first change in an area sets its conventions: record them in the design's Lasting Changes rather than raising the level.
- A bug with more than one independent cause is more than one task. Size each one.
- **Re-size when the work shows the level was wrong,** in either direction, and say so: "This touches the export format, so it's Complex now." The steps the new level adds start from there. A Trivial change that grows gets a task and a work entry; a Simple design that grows is rewritten from the Complex template.

What each level runs:

|  | Trivial | Simple | Complex |
| --- | --- | --- | --- |
| Task in TASKS.md | None; the commit is the record | Yes | Yes |
| Work entry | None | Yes | Yes |
| Spec (step 1) | None | When users would notice the change | When users would notice the change |
| Prototype (step 2) | None | When step 2 calls for one | When step 2 calls for one |
| Bug diagnosis review | None; the failing test is the proof | Only when a failing test doesn't prove the cause | Always |
| Tech design (step 3) | None | Simple template, no review pass | Complex template, two review passes, plus at most one blocker-verification pass |
| Slicing plan (step 4) | None | None; needing more than two slices is a reason to re-size | When the design needs more than two slices |
| Tests and code (step 5) | A bug's reproducing test, then the fix | Tests first, at the design's test points, then validate against the spec | Tests first, slice by slice, then validate against the spec |
| Diff review (step 5) | None | One st-crit pass on the diff | One st-crit pass on the diff |
| Close (step 6) | None; the commit message records the cause and the test | st-close steps 1–4 and 6; check the rows by eye | Every st-close step, including the searches |

## Trivial Changes

A Trivial change skips every step below. For a bug, first write the reproducing test and confirm it fails. Make the change, run the checks TESTING.md lists for the area it touches, and commit it, following Commits below. It needs no task and no work entry; the commit is the record.

## Step 1 — Spec

**Produces:** `docs/work/T-NNN-<name>/spec.md`, the behavior delta. **Skip when:** the task is Trivial, or the change does not alter anything the product's users would notice: a refactor, an internal fix, a performance change with no visible effect. Use the st-spec skill.

## Step 2 — Prototype (optional)

**Produces:** `docs/work/T-NNN-<name>/prototype/`. **Build one when:** the feature creates new UI; the feature is novel and the spec can't yet say how it should behave; a complex system has more than one plausible design approach; or a technical assumption needs proof before design, such as an OS behavior, a library's limits, or a performance ceiling. **Consider one when:** the feature changes existing UI. **Skip when:** there is no UI and every behavior and technical assumption is already settled.

A prototype answers a question, and it is thrown away. Its `README.md` starts with Question and Answer sections. Write the question before building it and the answer when it is done. If the answer settles an approach for the whole product, not just this feature, propose a DECISIONS.md entry.

- **UI prototypes:** a single self-contained HTML file. When the layout is uncertain, build two or three options side by side and pick the one that best fits the spec, saying why. Ask the customer only when the options trade off something the spec does not settle. Copy the chosen option's visible decisions (sizes, states, wording) into the spec's UI section.
- **Technical prototypes (spikes):** the smallest code that proves or disproves the assumption. It never becomes production code; the tech design cites its result.

## Step 3 — Tech Design

**Produces:** `docs/work/T-NNN-<name>/design.md`. **Skip when:** the task is Trivial. Use the st-design skill. Any spec claim the design changes goes back into the spec and through its review; a change users would notice is a high-judgment decision.

## Step 4 — Slicing Plan (Complex designs only)

**Produces:** `docs/work/T-NNN-<name>/slices.md`. **Skip when:** the task is Trivial or Simple, or the design fits in one or two slices. Use the st-slice skill.

## Step 5 — Tests and Code

**Produces:** the tests and code, a commit per slice, and a reviewed diff. Write the code your own way, inside the st-verify skill's gates: tests first at the design's test points, a commit per slice, validation against the spec and design, and one st-crit pass on the whole diff.

## Step 6 — Close

**Produces:** `close.md` in the work entry. **Skip when:** the task is Trivial, or has no work entry. Use the st-close skill as soon as the diff review is clean. A task with a work entry is not done until it is closed.

## Commits

Commit the work yourself, so the record never depends on someone remembering to: one commit for a Trivial change, one per slice (or for the whole design, if it has no slicing plan), one for the fixes from validation and the diff review, and one for the close.

- Stage only the files the work changed. Leave the customer's unrelated changes out; if a file holds both, ask before committing it.
- The first line names the change and cites the task ID. The body records the evidence: the tests added and that they pass, any drift from the design and why, and for a bug the cause and the reproducing test.
- Commit on the current branch. Never push, amend, rebase, or rewrite history unless the customer asks, and follow CONTEXT.md's never-do rules.
- In a project without version control, the close records the evidence in close.md instead.

## Testing

Choose the kind of test by what it has to prove:

| Test | Proves | Use for |
| --- | --- | --- |
| Unit | One module's behavior, with its edges faked | Logic with many cases: parsing, calculation, state transitions |
| Integration | Real modules working together across a boundary | Persistence, IPC, APIs, file system, anything where two parts must agree |
| Automated UI | A user journey through the running product | The task's use cases, and the regressions users would notice first |

- Test what the code does from the outside, never how it does it. A test that breaks during a refactor that changes no behavior is a bad test.
- Each use case gets at least one automated UI or integration test. Unit tests alone do not prove a use case works.
- Follow the project's `docs/engineering/TESTING.md` for tools and commands, and for its validation order: which checks a change runs, and when the full suite runs. If it does not exist, propose creating it the first time you write a test, with the commands that run each kind.
- When automated testing can't reach a behavior, add a step to its product area's manual test in `docs/manual-tests/<area>.md`, from st-dev-setup's `manual-test-template.md`, instead of skipping the check. Without one, that behavior has no lasting home.

## Bugs

A bug follows the same flow with a shorter spec:

1. **Diagnose.** Reproduce the bug, find the root cause, and say how confident you are and why. If you can't reach confidence, add logging or a probe to learn more before proposing a fix.
2. **Size it,** following Rigor Levels. A one-line fix with a failing test that reproduces it is usually Trivial; most other bugs are Simple. At Complex rigor, or when a failing test doesn't prove the cause, get the diagnosis reviewed with the st-crit skill before designing a fix.
3. **Spec,** only if the correct behavior was never a promise or the promise was wrong: use the st-spec skill to write the rule for the fixed behavior, and `SHALL CONTINUE TO` rules for what must not change.
4. **Tech design,** unless the fix is Trivial.
5. **Tests and code,** starting with the failing reproduction.
6. **Close,** unless the fix is Trivial.

## Between Steps

- **When a step finishes,** start the next one and say so in one line: "Spec approved after review. Starting the tech design."
- **st-elevate** is for when a step is blocked: it resolves a high-judgment decision or gathers critical input with the customer in one focused session.
- **st-crit** comes after work is written: its review is what lets a spec become Approved, and what lets a diff go to the close. Every review's findings are settled as `.steel-thread/framework/reviews.md` says.
- **Steel Thread files stay current throughout.** Each approved document is a checkpoint for pickup.md. Choices all future work has to follow go to DECISIONS.md, new terms to CONTEXT.md, future features to BACKLOG.md, and follow-up work to TASKS.md through the st-tasks skill, each with the customer's approval.
