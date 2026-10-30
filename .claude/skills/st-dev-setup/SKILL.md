---
name: st-dev-setup
description: Tailor Steel Thread's development process to the project's languages, frameworks, and platforms. Reads the codebase, writes the engineering reference docs, and adapts the development skills and templates to the stack. Use during setup, when the stack changes, or when the customer asks to fit Steel Thread to their stack.
---

Steel Thread's development process — `.steel-thread/framework/development.md` and the st-spec, st-design, and st-slice skills — is written for any stack. This skill makes this project's copy specific: it learns the stack, writes it down, and edits the process so that every later design and review asks the questions this stack needs. Run it again when the stack changes, such as a new platform or a new process boundary; a re-run updates what is there rather than starting over.

The skills live in this agent's skills folder (`.claude/skills/`, `.agents/skills/`, or `.kiro/skills/`; `.steel-thread/upstream/agent` names the agent).

## Step 1 — Learn the stack

Learn it from the repository, not the customer. Read:

- Manifests and build files, such as `package.json`, `Cargo.toml`, `Package.swift`, `*.xcodeproj`, `pyproject.toml`, `go.mod`, or `build.gradle`: the languages, frameworks, and key dependencies.
- The structure of the code: its components, and the boundaries between them that a change can cross, such as processes, languages, network calls, app extensions, or plugins. Note who owns state and where data is persisted.
- The platforms and targets it ships to, and the minimum versions.
- How it is tested: test frameworks, where tests live, and the commands that run them. Run the commands when it is fast and safe to, and note any you could not confirm.
- CI, lint, and formatting configuration.
- Existing docs: README, contributing guides, architecture notes, decision records, and AGENTS.md.

For a new project with no code yet, take the stack from the objective's constraints and DECISIONS.md. A stack choice that is still open is critical input: collect every open one and settle them together in one st-elevate session. Record the result in ARCHITECTURE.md; propose a DECISIONS.md entry only for a choice that meets the bar in `.steel-thread/framework/files/decisions.md`.

## Step 2 — Write the engineering docs

Create or update these in `docs/engineering/`. What belongs in each is defined in "Where information lives" in `.steel-thread/framework/docs-layout.md`; follow it. Describe what the code does now, citing example files; where the code is inconsistent, record it as an open question, not a rule. If the project already documents something elsewhere, link to it instead of copying it.

- **ARCHITECTURE.md** — start from `architecture-template.md` in this skill's folder. Fill it from the manifests and the code's structure.
- **CONVENTIONS.md** — start from `conventions-template.md` in this skill's folder. Fill it from the patterns the code keeps consistently.
- **Convention skills** — CONVENTIONS.md keeps only the rules every change follows. When one area of the code has rules of its own, such as UI, logging, or persistence, or the code shows a multi-step change it makes again and again, such as adding a setting or a migration, write it as a convention skill from `convention-skill-template.md` in this skill's folder: area guidelines for the first, a recipe for the second. Put each in this agent's skills folder, named without the `st-` prefix, and list it in CONVENTIONS.md's Convention Skills table with when to load it. Write one only where the code already shows the pattern.
- **TESTING.md** — each kind of test, its tools, where it lives, and the exact command that runs it. Give the validation order: the checks a change runs, scoped to the areas it touches, such as their tests, lint, and the formatter; and when the full suite runs, before the close or in CI. State the naming rule: a test's name states the behavior it proves, in users' terms, and suites are grouped by product area, because tests are where the product's behavior lasts (see "Planning Docs Are Scaffolding" in `.steel-thread/framework/docs-layout.md`). Name the product areas automation can't reach well, such as a device, a rich-text editor, or an OS dialog; their behavior lives in manual tests in `docs/manual-tests/<area>.md`, from `manual-test-template.md` in this skill's folder, created when the first one is needed.
- **CONTRACTS.md** — start from `contracts-template.md` in this skill's folder, if the code already has contracts other systems or users' files rely on: file formats, filenames other software reads, URL schemes, public APIs, update feeds. Otherwise leave it for the first task that adds one.
- **COMMON-FAILURE-MODES.md** — if it does not exist, create it from st-design's `templates/common-failure-modes-template.md`. Add the traps this stack is known for, each with `Last Seen:` left blank until one is observed here.

Propose stack terms that need a precise meaning to CONTEXT.md's vocabulary.

## Step 3 — Adapt the process

Edit the development skills and templates so they fit this stack. Typical changes:

- **st-design's templates:** name the stack's real boundaries in the Interface Contract (for example, Tauri commands and events, or Swift protocols and XPC services); fill Capabilities & Security with what this platform requires (for example, Tauri capabilities, or iOS entitlements and the privacy manifest); list the real targets in Cross-Platform, or remove it for a single-platform product; name the persistence mechanism and how its migrations work.
- **st-design's** `design-red-flags.md`**:** add red flags specific to this stack, with examples from this codebase.
- **st-design's review prompt:** make the reviewer an expert in this stack, such as a principal iOS engineer.
- **st-slice's template and the test table in Testing in development.md:** the real test tools and commands.

Rules:

- Add what this stack needs, remove what cannot apply, and use the stack's own terms instead of the generic ones.
- Keep the formats other files read (see Customizing Steel Thread in `.steel-thread/framework/steel-thread.md`).
- Prefer examples from this codebase over generic ones.
- Keep it small. Add a check only for a problem this stack is known for or this project has already hit, never one that only might happen.
- Log each file you change in `.steel-thread/customizations.md`: what changed and why.

## Step 4 — Report

Tell the customer in a few lines: the stack you found, the docs and convention skills you wrote, what you adapted in the process, and anything you could not confirm. Ask only what is blocking; everything else goes in the docs as an open question.

If the customer chooses to skip this skill, write `docs/engineering/ARCHITECTURE.md` with a single line naming the stack, so setup does not offer it again.