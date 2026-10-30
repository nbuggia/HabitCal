---
name: Habits slicing plan
task: T-003
design doc: docs/work/T-003-habits/design.md
design doc version/commit: ae1ee35
date created: 2026-10-29
last updated: 2026-10-29
status: Approved
---

# Slicing Plan: Habits

## 0. Sliceability Gate

- Design conclusion: "1. Model and store … 2. Form … 3. Errors and edges …" (§12)
- Design change required to slice: none

## 1. Rejected Alternative

Form first (add a habit, then show it). Rejected because the form would need a temporary in-memory list with no saving, and the riskiest guarantees (format v1, never overwriting unreadable data) would land last.

## 2. Slices

### Slice 1: Model, store, and habit rows

| Field               | Value |
| ------------------- | ----- |
| Status              | Done |
| Scope               | HabitCalKit: `Habit`, `Habits`, `HabitDraft`, `ScheduleLabel`, `StripDay`, `HabitLabels`, `HabitStore` (format v1, fixture, read-only guard). App: `-HabitCalDataDir`, load at launch into `AppModel.habits`/`dataState`, `persist()`, `toggleToday`, `toggle(_:on:)`; `HabitRow` (done button with its tooltip and spoken label, name and label, room for streaks), `StripView` in its final shape (keyboard cursor, VoiceOver actions, square tooltips, spoken value), the list's `ScrollView` with a max height, and the empty state. Test seams: `-HabitCalDataDir <folder name>` (a folder inside the container's Application Support, because the sandboxed app can't reach the test runner's temp folder) and Debug-only `-HabitCalSeedData <base64>`, written to habits.json before loading. |
| Demo criterion      | Unit: `habitIsDueOnlyOnScheduledWeekdaysFromTheDayItWasAdded`, `scheduleChangeAppliesFromTodayAndKeepsPastDays`, `secondScheduleChangeTheSameDayReplacesTheFirst`, `togglingOnlyWorksOnDueDaysUpToToday`, `stripShowsDoneMissedNotScheduledAndFutureForTheMonth`, `droppingTodayFromTheScheduleRemovesTodaysCheckOff`, `draftNeedsANameAndADay`, `draftTrimsNameAndNote`, `scheduleLabelNamesCommonSchedulesAndListsOthersMondayFirst`, `labelsDescribeEachDayAndButton`. Integration: `version1FixtureLoads`, `savedHabitsLoadBackUnchanged`, `missingFileLoadsEmpty`, `unreadableFileIsNeverOverwritten`, `newerFormatIsNeverOverwritten`, `saveBeforeLoadIsRefused`, `saveReplacesTheFileWhole`. UI: `checkingOffTodayFillsTheButtonAndTodaysSquare`, `fixingAMissedDayInTheStrip`, `habitsSurviveRelaunch`, `emptyListShowsPrompt`, `stripIsOneTabStopThatArrowsAndSpaceDrive`. Manual: VoiceOver adjusts the strip day by day and toggles with the default action. |
| Dependencies        | T-002's `AppModel`, `HabitListScreen`, and launch options. |
| Explicitly deferred | The form, the right-click menu, and the Edit menu (Slice 2). The E.5 message and E.6 banner text (Slice 3); in Slice 1 an unreadable file shows an empty list and nothing is saved, because the store refuses. |
| Invalidation risk   | If `.focusable(interactions: .edit)` or `.onKeyPress` doesn't make the strip a Tab stop in a popover, or VoiceOver's adjustable action doesn't work there, that's a DESIGN finding (E.8). Strict v1 decoding needs a key check beyond `JSONDecoder` (which ignores unknown keys); if that proves impractical, the contract changes and goes back to design. |
| Size justification  | Checking off is the core value (T-003 spec, Users), and it works end to end on seeded data. |
| Test gate           | Failing tests first at the design's test points (`swift test --package-path HabitCalKit`, then the area's XCUITests), then implement. |

### Slice 2: Habit form

| Field               | Value |
| ------------------- | ----- |
| Status              | Pending |
| Scope               | Name click (with the hover pencil) to edit, `Screen.form` + `AppModel.form`, `openAddForm`, `openEditForm`, `openDeleteConfirmation`, `saveForm`, `cancelForm`, `deleteFromForm`, `escape()` for the form; `HabitFormScreen` (header, name with focus and Return, day buttons in week-start order, notes, hints, delete and its confirmation, length clamp); "+ Add habit"; `.contextMenu` with Edit… and Delete…; the Edit menu in `MainMenu`. "+ Add habit" is disabled while `dataState` is `.unreadable`. |
| Demo criterion      | UI: `addingAHabitShowsItWithItsScheduleLabel`, `editingAHabitRenamesItAndChangesItsDays`, `deletingAHabitAsksFirstThenRemovesIt`, `escapeInFormReturnsToList`, `escapeInNotesReturnsToList`, `typingInTheNameFieldKeepsFocus`. Manual: ⌘C/⌘V in the form. |
| Dependencies        | Slice 1's `Habits` operations, `persist()`, and rows. |
| Explicitly deferred | Error states (Slice 3). |
| Invalidation risk   | If `.keyboardShortcut(.cancelAction)` doesn't catch Esc from a focused field in the popover, that's a DESIGN finding (design finding 3). If typing loses focus in the popover's name field (FM-006, design finding 1), likewise. |
| Size justification  | The add/edit/delete journeys (UC-1, UC-4, UC-5) complete. |
| Test gate           | Failing tests first at the design's test points (`swift test --package-path HabitCalKit`, then the area's XCUITests), then implement. |

### Slice 3: Errors, accessibility, and manual checks

| Field               | Value |
| ------------------- | ----- |
| Status              | Pending |
| Scope               | E.5 message with the file path; E.6 banner; the form's spoken labels, plus `habitControlsHaveSpokenLabels` checking every habit control from Slices 1–2; `docs/manual-tests/habits.md`. |
| Demo criterion      | UI: `unreadableDataShowsMessageAndDisablesAdd`, `habitControlsHaveSpokenLabels`. Manual: habits look (light/dark/Increase Contrast), many habits scroll, VoiceOver strip, save-failure banner. Then the full suite. |
| Dependencies        | Slices 1 and 2. |
| Explicitly deferred | Streaks (T-004). |
| Invalidation risk   | The E.1 max height (visible screen height − 330 pt) may need tuning on small screens; the E.6 banner is only reachable manually (a read-only folder), so its wording is checked by eye. |
| Size justification  | Closes the edge cases and accessibility rules. |
| Test gate           | Failing tests first at the design's test points (`swift test --package-path HabitCalKit`, then the area's XCUITests), then implement. |

## 3. Review Findings

| #   | Finding | Category | Severity | Decision | Slices | Rationale | Next step |
| --- | ------- | -------- | -------- | -------- | ------ | --------- | --------- |
| 1 | VoiceOver strip built in Slice 1, proven in Slice 3 | SLICING | MAJOR | ACCEPT | 1, 3 | Risk found late | Manual VoiceOver check moved to Slice 1 |
| 2 | Add works on unreadable data after Slice 2 | SLICING | MINOR | ACCEPT | 2 | Wrong intermediate state | Add disabled on `.unreadable` in Slice 2 |
| 3 | Label/tooltip split unclear | SLICING | MINOR | ACCEPT | 1, 3 | Ownership | Row labels/tooltips in Slice 1; form labels and the full check in Slice 3 |
| 4 | Name-click edit unassigned | SLICING | MINOR | ACCEPT | 2 | Coverage | Added to Slice 2 |
| 5 | Invalidation risks incomplete | SLICING | MINOR | ACCEPT | 1–3 | Named risks | Added |
| 6 | Plan pinned to an uncommitted design | SLICING | MINOR | ACCEPT | all | Drift baseline | Pinned to ae1ee35 |

## 4. Dependency Graph

Slice 1 → Slice 2 → Slice 3

## 5. Checkpoint Log

### After Slice 1

- Commit: the "T-003 slice 1" commit.
- Affected remaining slices reviewed: 2 (it uses `Habits.add/update/delete`, `persist()`, and `HabitRow`; all are in place) and 3 (unchanged).
- Changed: the test data seam is a folder name inside the container (`-HabitCalDataDir`) plus `-HabitCalSeedData`, because the sandboxed app can't reach the test runner's folders. The strip's focus test proves focus by behavior (Tab then ← moves the day), because SwiftUI doesn't expose `hasKeyboardFocus` on the strip. UI tests now share `HabitCalUITestCase`. A popover screenshot (dark mode) matches the prototype. Manual VoiceOver strip check is pending the customer (docs/manual-tests/habits.md, written in Slice 3).

## 6. Design Drift

| Change | Affected slices | Reevaluation |
| ------ | --------------- | ------------ |
| `-HabitCalDataDir` is a folder name under the container, and `-HabitCalSeedData` seeds habits.json (sandbox) | 1–3 | Tests in all slices use the seed; no design change |
