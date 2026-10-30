# Conventions

No code exists yet. These are the rules v1 starts with; T-002's close replaces the planned examples with real files.

## Structure

- Habit, schedule, streak, week-start, and saving rules go in `HabitCalKit/Sources/HabitCalKit/`, with their tests in `HabitCalKit/Tests/HabitCalKitTests/`.
- Anything that needs AppKit, SwiftUI, or ServiceManagement goes in the `HabitCal` app target: menu bar code in `App/` and `MenuBar/`, screens in `Views/`.
- One SwiftUI view per file, named for the screen or part it draws (`HabitRow.swift`).

## Boundaries

- HabitCalKit never imports AppKit, SwiftUI, or ServiceManagement. If a rule needs one of them, the rule is split: the decision goes in HabitCalKit, and the call into macOS goes in the app.
- Views never compute due days, streaks, or labels themselves; they read them from HabitCalKit through `AppModel`.
- Only `HabitStore` touches the data file. Nothing else reads or writes it (D-004, D-006).
- Never make a network request. The sandbox has no network entitlement, and adding one needs a decision (D-007).

## Dates

- A calendar day is a `Day`, never a `Date`. Convert `Date` → `Day` once, at the app's edge, with the user's current calendar and time zone (FM-002).
- "Today" comes only from the injected `Clock`. Never call `Date()` or `Date.now` in HabitCalKit or the views (FM-007).
- Use `Calendar.autoupdatingCurrent`, never a cached `Calendar.current`, wherever the Mac's settings matter (FM-005).

## Naming

- Use the specs' vocabulary in type and function names: `Habit`, `Schedule`, `isDue(on:)`, `checkOff`, `currentStreak`, `bestStreak`, `weekStart`.
- Tests are named for the behavior they prove, in users' terms; see TESTING.md.

## Errors

- HabitCalKit throws typed errors (`HabitStoreError`) and never crashes on bad input. No `try!`, `fatalError`, or force-unwrap on data read from disk.
- The app shows a store error as the inline message the T-003 spec gives (E.5, E.6), and logs it with `os.Logger` (subsystem: the bundle ID, category: the component).

## State

- UI state lives in the `@MainActor @Observable` `AppModel`. Views receive it from the environment and change it only through its methods.
- Every change to habits goes through one `AppModel` method that updates the store and saves, so nothing is changed in memory without being saved (T-003 B.18).

## Comments

- Comments explain why: a reason that isn't obvious, a workaround, an unexpected edge case. Never restate what the code does.
- Comments describe the code as it is. What a change did goes in its commit message, never in a comment such as "changed from X" or "added for T-014".
- Explain each thing once: in the doc comment on the declaration, not again at each call site. A doc comment describes behavior, not its callers.
- Don't remove a comment during an unrelated change. Change it only when the code it describes changes.

## Convention Skills

None yet. Write one when the code shows an area with its own rules, or a change that recurs.
