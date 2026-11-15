# Steel Thread Docs Layout

Where the project's documents and Steel Thread's own files live, and what each lasting document holds. Read this when you need to find a file, and before you create a work entry, write a planning document, close a task, or create or edit a document in `docs/engineering/`. The process that produces these documents is in `.steel-thread/framework/development.md`.

## File Structure

```
docs/
  PRD.md                        ← the objective, and product intent per feature area
  CONTEXT.md                    ← vocabulary, tenets, what you must never do
  TASKS.md                      ← phases and tasks, in priority order
  BACKLOG.md                    ← future features, not yet committed work
  DECISIONS.md                  ← log of decisions and why they were made
  manual-tests/                 ← human-run checks, by product area
    <area>.md
    next-pass.md                ← checks waiting for the customer's next test pass
  work/                         ← scaffolding, never searched: one folder per task
    T-014-first-save-filename/
      spec.md                   ← the behavior delta
      prototype/
      design.md
      slices.md
    T-015-export-spaces/        ← a folder even when it holds one document
      design.md
    T-009-file-conflicts/       ← a done task; history only
  engineering/                  ← project-wide technical reference
    ARCHITECTURE.md             ← what is there
    CONTRACTS.md                ← promises to users' files and other systems
    TESTING.md                  ← how to check a change
    COMMON-FAILURE-MODES.md     ← traps hit here or known for the stack
    REVIEW-PATTERNS.md
.steel-thread/
  customizations.md             ← what this project changed in Steel Thread, and why
  review-log.md                 ← each diff review finding and what happened to it
  framework/                    ← Steel Thread itself; customize it for this project
    steel-thread.md                 ← the operating manual, read every session
    files/                      ← formats and rules for each customer file, one per file
    development.md              ← the software development process, from spec to tests
    reviews.md                  ← how reviews run and how their findings are settled
    docs-layout.md              ← this file
    templates/                  ← starter files used during setup
  upstream/                     ← owned by the installer — never edit
```

Automated tests live where the stack's tooling expects them; TESTING.md says where each kind is. Manual tests and CONTRACTS.md are created the first time a task needs one.

Rules:

- A work entry is named after its task in TASKS.md: `T-NNN-<short-name>`. Every work entry has a task; propose one with the st-tasks skill if it doesn't.
- A work entry is always a folder, even when it holds a single document, so adding a second one never moves the first.
- `docs/work/` holds every task's work entry, open and done. Finishing a task leaves its folder in place.
- Never search `docs/work/`. It is scaffolding, and the installer lists it in `.ignore` so search tools skip it. Open an entry only by its path: the open task you are working on, or a done one for history — why something was built the way it was, when DECISIONS.md and the lasting documents don't say, or when the customer asks. Never use a done entry as current behavior; current behavior is in the code, the tests, and the lasting documents.
- Nothing lasting links into `docs/work/`: no code comment, test, lasting document, or done task. Cite a task ID, D-NNN, FM-NNN, or commit instead. Until a task is done, its Notes in TASKS.md may name its folder.

## Planning Docs Are Scaffolding

**Planning docs are inputs to one task. When the task is done, everything the next change needs is in the code, the tests, and the lasting documents.** From then on, nothing relies on or links to that task's planning docs; they are kept only as history.

The planning docs are a task's spec, prototype, tech design, and slicing plan, with their review findings. While the task is open they can be rewritten freely: there is no history to keep, because none of them is a record. The design's Lasting Changes list everything that lasts; finishing the task applies them, and leaves the folder in `docs/work/` as history.

Behavior is intended or accidental:

- **Intended behavior is a promise.** Behavior is a promise if a test whose name states it checks it, a manual test covers it, CONTRACTS.md lists it, or a code comment explains it.
- **Anything else is an accident,** and can change. What a test asserts along the way, such as a snapshot or exact wording, is not a promise unless the test's name says so.

So a test's name is a behavior statement in users' terms, and a change that breaks a promise is a change users would notice.

**Current behavior** is rebuilt from the promises, never from a planning doc. To learn how an area behaves today, read its feature section in `docs/PRD.md`, its tests by name, its manual tests, CONTRACTS.md, and the comments in the code it runs through.

## Document States

Every planning document records its state on a `status:` line in its frontmatter. Prototypes have no status: an empty or filled Answer section shows whether the question was answered.

| Document | States |
| --- | --- |
| Spec, tech design, slicing plan | Draft → Approved, or Blocked |
| Slice, inside a slicing plan | Pending → Done, or Blocked |

What each state means:

- **Draft** — being written. Nothing downstream may rely on it.
- **Approved** — it passed its review and has no open `[NEEDS DECISION]` markers, so the next step can start from it. You set it.
- **Pending** — the slice has not started.
- **Done** — the slice is finished.
- **Blocked** — the document or slice cannot proceed without the customer: a high-judgment decision or critical input. Say why on the next line, starting `Blocked:`.

Rules:

- **A step starts only from an Approved document.** A tech design is drafted from an Approved spec, and a slicing plan from an Approved design. A prototype is the exception: it can run while the spec is still Draft, because its answer often settles the spec's open questions.
- **Going back is allowed, and must be said out loud.** If a later step shows an Approved document is wrong, revise it, set it back to Draft, tell the customer why, and block only the work that depends on the part that changed.
- **A task's documents finish together, when the task is done.** There is no Done state for a document: finishing the task applies the design's Lasting Changes, and the folder stays behind as history.

## Where information lives

Each lasting document answers one question, and each fact lives in exactly one of them; the others link to it.

|  | ARCHITECTURE.md | DECISIONS.md |
| --- | --- | --- |
| **Answers** | What is there, and which boundaries a change must not cross? | Why is it this way, and what was rejected? |
| **Voice** | Describes: "The Rust core owns all file access." | Explains: "We chose X over Y because…" |
| **Holds** | The stack and key dependencies, components, boundaries, where state lives, data flow, persistence, and which component implements each contract | Choices future work must follow that are expensive to undo or likely to be argued again, with what was rejected |
| **Belongs here if** | You would draw it on a diagram | Someone will propose the opposite, and the answer is "we considered that" |
| **Changes by** | Editing in place; it always describes now | Appending; an old entry is superseded, never edited |

There is no conventions file: how to make a change is shown by the code itself, and a change follows the patterns the surrounding code uses. DECISIONS.md never states the current rule; ARCHITECTURE.md does, and cites the decision for the reason. One fact can touch both without repeating itself:

- **ARCHITECTURE.md:** "Tauri 2 app: a Rust core and a WebView UI. Only the core touches the filesystem (D-003)."
- **DECISIONS.md:** "D-003 · Tauri over Electron. Why: bundle size and memory. Rejected: Electron, which ships a second runtime."

The neighbors:

- **Tests** hold behavior. Each test's name states the behavior it proves, in users' terms, and suites are grouped by product area.
- **Manual tests** hold behavior that automation can't reach, by product area, in `docs/manual-tests/<area>.md`. A person runs them, often the customer. Checks waiting for the customer's next run are queued in `docs/manual-tests/next-pass.md`, which the st-verify skill keeps.
- **CONTRACTS.md** holds the promises other systems and users' files rely on: file formats, on-device filenames, URL schemes, update feeds, public APIs. ARCHITECTURE.md names the component that implements each one.
- **PRD.md** holds the objective, and product intent per feature area: who it is for, why it matters, what it doesn't do, and what done means. `.steel-thread/framework/files/prd.md` has its format.
- **Convention skills** hold the rules for one area of the code, such as UI or logging, or the steps for one recurring kind of change, such as adding a feature flag. They live in the agent's skills folder, named without the `st-` prefix, so Steel Thread updates never touch them. A skill that keeps project paths in its examples can be copied to another project on the same stack.
- **Code comments** hold the why of non-obvious code, including traps where the obvious approach breaks, citing D-NNN or FM-NNN. They describe the code as it is now; what a change did belongs in its commit message.
- **TESTING.md** says how to check a change: the kinds of test, where each lives, their tools, and the commands that run them.
- **COMMON-FAILURE-MODES.md** records traps the project has hit, or that its stack is known for.
- **BACKLOG.md** holds future features; **CONTEXT.md** holds the vocabulary, tenets, and never-do rules.

If the project already has docs in a different layout, do not reorganize them unasked. Propose the move once, as a task, and follow the existing layout until the customer agrees.
