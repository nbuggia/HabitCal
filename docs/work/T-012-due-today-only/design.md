---
task: T-012
rigor: Simple
status: Approved
date created: 2026-10-30
---

# Tech Design: Due Today Only

## Summary

`Habits` gains `dueOn(_:)` and `notDueOn(_:)`, which split the list by `Habit.isDue(on:)` and keep the order the habits were added. `HabitLabels` gains the folded row's text and spoken label. `AppModel` gains `showsNotDue`, cleared on every open and set when a saved habit isn't due today. `HabitListScreen` shows the due rows, then "Nothing due today" when there are none, then the folded row with the not-due rows under it when it's open. No stored data changes.

## Approach

- `HabitCalKit/Sources/HabitCalKit/Habits.swift`: `public func dueOn(_ day: Day) -> [Habit]` and `public func notDueOn(_ day: Day) -> [Habit]`, both filters on `all`.
- `HabitCalKit/Sources/HabitCalKit/HabitLabels.swift`: `notDueRowTitle(count:)` returns "3 not due today", and `notDueRowSpoken(count:)` returns "1 habit not due today" or "3 habits not due today".
- `HabitCal/AppModel.swift`: `private(set) var showsNotDue = false` and `toggleNotDue()`. `resetForOpen()` sets it to false (B.2). `saveForm()` sets it to true when the saved habit isn't due today (B.4); `add` already returns the new habit's ID.
- `HabitCal/Views/HabitListScreen.swift`: the scroll view's stack shows the `dueOn(model.today)` rows; "Nothing due today" when that list is empty and `notDueOn` isn't; then the folded row (a borderless button: the title, then a `caret-right` or `caret-down` Phosphor icon at 11 pt, both secondary); then the `notDueOn` rows when `showsNotDue` is true. The button's accessibility label is the spoken label, and its value is "collapsed" or "expanded". `model.today` is already observed, so a day change re-splits the list (B.5).
- Add `ph-caret-down` to the asset catalog (Phosphor 2.1.1, regular), formatted like the other `ph-*` SVGs.

## Test Points

| Test (named for the behavior it proves) | Kind (unit / integration / UI / manual) | Spec rules proved |
| --- | --- | --- |
| `dueAndNotDueSplitTheListInOrderAdded` | unit | B.1, B.5 (the split is by the day passed in) |
| `notDueRowLabelsCountHabits` | unit | B.2 |
| `testHabitsNotDueTodayFoldIntoARow` | UI | B.1, B.2, B.6 |
| `testNothingDueTodayShowsAboveTheFoldedRow` | UI | B.3 |
| `testSavingAHabitNotDueTodayOpensTheFoldedRow`, `testAddingAHabitShowsItWithItsScheduleLabel` | UI | B.4 |
| Existing UI tests that reach a not-due habit ("Run" on a Thursday) open the folded row first | UI | B.6 |
| `testEscStillClosesAfterFoldingAwayTheFocusedStrip` | UI | B.2 (focus) |
| Screenshots of the list closed and open; midnight manual test | manual | §5, B.5 |

## Lasting Changes

| Change | Goes to |
| --- | --- |
| The list shows due habits; the others fold into "N not due today" | PRD.md (habit list behavior), via the customer's approval |
| Folded row opens after saving a not-due habit | Doc comment on `AppModel.saveForm` |

## Review Findings

| # | Severity | Finding | Decision | Source |
| --- | --- | --- | --- | --- |
| 1 | MAJOR | Closing the folded row, or a day change, can remove the focused strip and leave Esc dead (FM-006) | ACCEPT, defensively: not reproduced. With Run's strip keyboard-focused (by Tab) and no fix, folding it away left Esc working. `testEscStillClosesAfterFoldingAwayTheFocusedStrip` guards that path; `AppModel.listDidHideRows` refocuses the hosting view anyway, for the midnight path no UI test can reach | Pass 1 |
| 2 | MAJOR | The edit half of B.4 was untested | ACCEPT: `testSavingAHabitNotDueTodayOpensTheFoldedRow` | Pass 1 |
| 3 | MINOR | With Keyboard navigation off, folded habits aren't reachable by keyboard (T-003 E.8) | ACCEPT as spec change: B.8 narrows E.8 to the platform norm | Pass 1 |
| 4 | MINOR | A saved habit may sit below the scroll in a long list | ACCEPT as spec change: B.4 says "listed", not "in view" | Pass 1 |
| 5 | MINOR | B.5 isn't proven at the view level; manual tests expected the old list | ACCEPT: midnight manual test covers B.5; habits.md updated | Pass 1 |
| 6 | MINOR | The Nothing-due test didn't prove "above" | ACCEPT: compares frames | Pass 1 |
