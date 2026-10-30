# Conventions

\[How to make a change here: the practices a reviewer would flag a diff for breaking. One rule per line, written as an instruction, with an example file that follows it, and the D-NNN behind it when there is one. What the system is goes in ARCHITECTURE.md. This file holds the rules every change follows; rules for one area of the code, and the steps for one recurring kind of change, go in convention skills, listed at the end. Leave out any section with nothing in it.\]

## Structure

- \[Where new code of each kind goes. Example: `src/features/export/`\]

## Boundaries

- \[How a change respects each boundary in ARCHITECTURE.md: "UI code never touches the filesystem; add a command in `commands.ts` (D-003)."\]

## Naming

- \[Naming rules a reviewer would enforce.\]

## Errors

- \[How errors are created, passed across boundaries, shown to users, and logged.\]

## State

- \[Where new state goes and who may change it.\]

## Comments

\[Defaults. Keep them unless the code follows other rules.\]

- Comments explain why: a reason that isn't obvious, a workaround, an unexpected edge case. Never restate what the code does.
- Comments describe the code as it is. What a change did goes in its commit message, never in a comment such as "changed from X" or "added for T-014".
- Explain each thing once: in the doc comment on the declaration, not again at each call site. A doc comment describes behavior, not its callers.
- Don't remove a comment during an unrelated change. Change it only when the code it describes changes.

## Convention Skills

| Skill | Load when |
| --- | --- |
| \[`ui-guidelines`\] | \[Before any change to `src/ui/`\] |
| \[`add-feature-flag`\] | \[A change is gated behind a feature flag\] |
