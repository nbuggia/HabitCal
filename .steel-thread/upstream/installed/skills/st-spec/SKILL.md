---
name: st-spec
description: Shape an idea into a spec for one task, saying what changes in the product's behavior for its users and why, never how. Rebuilds how the product behaves today, sharpens the idea to its core value, keeps the task to the smallest complete set of use cases, sends the rest to the backlog, and recommends a prototype when one would clarify it. Use when the customer wants to spec a feature, write requirements, plan what goes in a release, or change how a feature behaves.
based-on: Matt Pocock, to-spec (https://github.com/mattpocock/skills); GitHub Spec Kit, spec-template (https://github.com/github/spec-kit); Kiro, feature and bugfix specs (https://kiro.dev/docs/specs/)
---

A spec is the behavior delta for one task: what the task changes in how the product behaves for its users, and why. It is scaffolding. When the task closes, its rules live on in tests, manual tests, and CONTRACTS.md, and its intent in the PRD; the spec itself stays behind as history. The format and most of the guidance are in `spec-template.md`; follow it closely. This is step 1 of `.steel-thread/framework/development.md`.

In this skill, **users** are whoever consumes what the task changes: the people using the product for a UI, the callers for an API or library, the developer typing a CLI command, the code that reads a file format. The **customer** is the person you are working with.

This skill also owns `docs/BACKLOG.md` and release planning. Its format is in `.steel-thread/framework/files/backlog.md`.

## Step 1 — Find the task and today's behavior

Every spec belongs to one task. Find it in TASKS.md, or propose one with the st-tasks skill. The spec goes in `docs/work/T-NNN-<name>/spec.md`. If that file exists, revise it in place.

Read CONTEXT.md and the Active decisions that touch the feature. Then rebuild how the product behaves today in the area the task changes, from the sources "Planning Docs Are Scaffolding" in `.steel-thread/framework/docs-layout.md` lists. Write the summary into the spec's Current Behavior section, citing where each point came from. It is for this task's review; it is never kept anywhere else. A new feature has no current behavior: say so in one line.

- **A small change** leaves the core value, users, and scope as they are, such as a bug fix's rule or a changed limit. Go straight to step 3. In step 4, recommend st-crit only if a use case changed.

## Step 2 — Shape the idea

Work from what the customer, the conversation, and the project have already told you, and settle what you can yourself. A gap only the customer can fill, such as who the users are or what the feature is for, is critical input (see `.steel-thread/framework/development.md`): collect those gaps and resolve them together in one st-elevate session, never one question at a time. Settle these, in this order:

1. **Core value:** who the users are, and the one thing the feature must do for them to be worth building.
2. **Use cases:** the ones this task delivers, and the ones that wait.
3. **Scope:** for a new feature, choose the smallest complete set of use cases that delivers the core value for real. For a feature that already exists, add only what this task's purpose needs.

Then challenge the scope. Does it deliver the core value, or only demo it? Could anything wait, and is anything required missing? Write its rules once it holds up. Moving a use case the customer asked for out of this task is a high-judgment decision; ask before you do it.

Use cases that wait go in the spec's Deferred section. At close, they become BACKLOG.md rows, as Later unless the customer says Next. Don't prioritize them now.

While shaping, watch for two things:

- **The idea has become several tasks.** Split when a group of use cases and rules can be understood, changed, and tested independently; never split only because it belongs to another platform. Choose the boundaries, tell the customer what you split and why, and propose a task for each part with the st-tasks skill. Each task gets its own spec.
- **A prototype would answer it faster.** Apply the prototype criteria in `.steel-thread/framework/development.md`, step 2. If they call for one, write a Draft spec with what is settled, put the prototype's questions under Open Questions, and build the prototype in the same work entry. Pick the spec back up when it is answered.

## Step 3 — Write it

Fill in the template. Every spec has Summary, Current Behavior, and Behavior; a new feature also has Users, Not Doing, and Use Cases. Include any other section only when it has content, and leave out its heading otherwise.

Size it to the task. Behavior is as long as the change needs, and everything around it stays thin: at Simple rigor a spec is usually 30–60 lines, and at Complex 80–150, most of them in Behavior. If the Summary, Users, and Behavior say the same thing, cut the framing, not the rules.

Then check:

- **No implementation:** no code identifiers, internal file paths, components, libraries, or test plans. External contracts are behavior and belong in the spec, such as URLs, file formats, keyboard shortcuts, and commands users type; list each one under Contracts.
- **A complete delta:** every rule this task adds or changes is under New or Changed, and the behavior it must not break is under Unchanged, as `SHALL CONTINUE TO` rules. A changed rule says what it was.
- **Testable rules:** each rule can become a test name, or a step in a manual test.
- **Edge cases:** walk this list and write a rule for each one that applies: empty, loading, and error states; cancelling partway; permission denied; offline or a slow network; timeouts; two actions racing; more than one instance open at once; stale or missing data; focus lost mid-interaction; keyboard use and accessibility; and interactions with neighboring features. Err toward one more edge case, not one fewer.
- **Vocabulary:** terms match CONTEXT.md; propose any new term.

## Step 4 — Review and approve

Run an st-crit review unless step 1 classified this as a small change; then go straight to approval. For the review, give the critic the draft and the Active decisions that touch it. The critic is a user of the feature, joined by a product lead who has watched specs like this fail. They attack the core value, the scope, the Current Behavior summary's accuracy, and any rule that is ambiguous, untestable, or missing for a use case. They do not organize the deferred items.

Revise the spec for each finding, or record it as an accepted risk. A finding becomes a `[NEEDS DECISION]` marker only when it is a choice the customer has to make, not a reviewer's preference.

A spec with open markers stays Draft and is blocked on them; ask the customer to resolve them together. Otherwise, set it to Approved and tell the customer in a few lines: the Summary, the rules that change, and what the review changed. If they want the whole feature's behavior, not just the change, give them the Current Behavior summary with this task's changes applied. Propose a DECISIONS.md entry for each rule that applies to the whole product rather than this feature, such as who the product is not for, the accessibility level, or how long data is kept. Then start the next step: the prototype if one is pending, otherwise the tech design.

## Planning a release

A product release is a phase in TASKS.md. When the customer plans one, or the st-whats-next skill offers it after a phase closes:

1. Read BACKLOG.md. Propose the release from its Next rows, plus anything the customer adds, with a short purpose name.
2. Once the customer agrees, add the phase and one task per feature with the st-tasks skill, which deletes the BACKLOG.md rows that became tasks.
3. Write each task's spec when its work starts.
