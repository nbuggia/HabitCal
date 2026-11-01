# Conventions

The rules every change follows.

## Structure

- Habit, schedule, streak, week-start, and saving rules go in `HabitCalKit/Sources/HabitCalKit/`, with their tests in `HabitCalKit/Tests/HabitCalKitTests/`.
- Anything that needs AppKit, SwiftUI, or ServiceManagement goes in the `HabitCal` app target: menu bar code in `App/` and `MenuBar/`, screens in `Views/`.
- One SwiftUI view per file, named for the screen or part it draws (`CalendarView.swift`).
- Add a file by putting it in its folder: the project uses folder-synced groups, so there's no project-file edit.

## Boundaries

- HabitCalKit never imports AppKit, SwiftUI, or ServiceManagement. If a rule needs one of them, the rule is split: the decision goes in HabitCalKit, and the call into macOS goes in the app.
- Views never compute due days, streaks, labels, or orderings themselves; they read them from HabitCalKit through `AppModel` (e.g. `WeekStart.orderedWeekdays`, `MonthNames.spokenCalendarDay`).
- Only `HabitStore` touches the data file. Nothing else reads or writes it (D-004, D-006).
- Never make a network request. The sandbox has no network entitlement, and adding one needs a decision (D-007).

## Dates

- A calendar day is a `Day`, never a `Date`. Convert `Date` → `Day` once, at the app's edge, with the user's current calendar and time zone (FM-002).
- "Today" comes only from `AppModel.today`, set by `DayWatcher` from a `TodaySource`. Never call `Date()` or `Date.now` anywhere else (FM-007).
- Use `Calendar.autoupdatingCurrent`, never a cached `Calendar.current`, wherever the Mac's settings matter (FM-005).

## Popover

- Handle Esc in `AppModel.escape()`, one level per press. Never use `.onKeyPress` or `.onExitCommand` for it in an unfocused screen: they need focus, and Esc reaches `cancelOperation` without it (FM-006).
- A new screen is a case in `Screen` and a branch in `PopoverRoot` and `escape()`. Keep a screen's editable state in its own `AppModel` property, never in the `Screen` case (focus resets when `screen` changes).
- A form's Close button carries `.keyboardShortcut(.cancelAction)`: it catches Esc even from a focused text field, whose field editor otherwise swallows `cancelOperation`. Give it to one button per screen.
- Give a text field its own `@State` text and enforce limits there, in `.onChange`; a clamped value pushed back through a model binding doesn't reach a field while it's being typed in.
- Set `@FocusState` one run-loop turn after a screen appears (`DispatchQueue.main.async`); set synchronously in `onAppear`, it's lost in the popover.
- The popover is narrow (232 pt, a 200 pt column): screens pad by `PopoverRoot.margin` horizontally and 12 pt vertically; put a row's caption on its own line under its label and control, and give multi-line text `.fixedSize(horizontal: false, vertical: true)` so it wraps instead of truncating. Check new screens by screenshot (TESTING.md).
- Popover buttons use `.buttonStyle(.hover)` (`HoverButtonStyle`) for their hover and pressed states, never `.borderless` or `.plain`. Text buttons take an `outset` of 3–4 pt; buttons with their own fill take `overLabel: true` and their shape's corner radius (T-021). Links keep `.link`.
- A segmented `Picker` won't shrink below its labels; in the popover, use equal-width buttons instead when the labels are long (T-016).
- Don't add `.accessibilityLabel` to a `Picker` or `Toggle` that has a title: SwiftUI already speaks the title, and a second label doubles it.

## Naming

- Use the specs' vocabulary in type and function names: `Habit`, `Schedule`, `isDue(on:)`, `checkOff`, `currentStreak`, `bestStreak`, `weekStart`.
- Tests are named for the behavior they prove, in users' terms; see TESTING.md.

## Errors

- HabitCalKit throws typed errors (`HabitStoreError`) and never crashes on bad input. No `try!`, `fatalError`, or force-unwrap on data read from disk.
- The app shows a store error as the inline message the T-003 spec gives (E.5, E.6), and logs it with `os.Logger` (subsystem: the bundle ID, category: the component).

## State

- UI state lives in the `@MainActor @Observable` `AppModel`. Views receive it from the environment and change it only through its methods.
- Every change to habits goes through one `AppModel` method that applies a `Habits` operation and then calls `persist()`, so nothing is changed in memory without being saved (T-003 B.18).

## Comments

- Comments explain why: a reason that isn't obvious, a workaround, an unexpected edge case. Never restate what the code does.
- Comments describe the code as it is. What a change did goes in its commit message, never in a comment such as "changed from X" or "added for T-014".
- Explain each thing once: in the doc comment on the declaration, not again at each call site. A doc comment describes behavior, not its callers.
- Don't remove a comment during an unrelated change. Change it only when the code it describes changes.

## Convention Skills

None yet. Write one when the code shows an area with its own rules, or a change that recurs.
