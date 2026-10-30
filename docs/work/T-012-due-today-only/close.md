# Close: T-012 Due today only

| Item | Landed in |
| --- | --- |
| Summary and why (the list is today's to-do list) | Proposed for docs/PRD.md, "Feature: Habits"; awaiting the customer's approval |
| B.1 only due habits have rows | Tests `dueAndNotDueSplitTheListInOrderAdded`, `testHabitsNotDueTodayFoldIntoARow` |
| B.2 folded row, "N not due today", closed on every open, spoken label and value | Tests `notDueRowLabelsCountHabits`, `testHabitsNotDueTodayFoldIntoARow`; `AppModel.resetForOpen` |
| B.3 "Nothing due today" above the folded row | Test `testNothingDueTodayShowsAboveTheFoldedRow` |
| B.4 saving a not-due habit opens the folded row (listed, not scrolled to) | Tests `testSavingAHabitNotDueTodayOpensTheFoldedRow`, `testAddingAHabitShowsItWithItsScheduleLabel`; doc comment on `AppModel.saveForm` |
| B.5 habits move between the list and the row at midnight | docs/manual-tests/menu-bar.md, "Today's marker and habits move at midnight while the popover is open"; `AppModel.today` refocuses on change |
| B.6 a shown not-due row is unchanged, and its strip still fixes past days | `testHabitsNotDueTodayFoldIntoARow`; existing UI tests open the row first (`showNotDue()`) |
| B.7 empty-list prompt unchanged | Test `testEmptyListShowsPrompt` |
| B.8 the folded row is a Tab stop only with Keyboard navigation on (narrows T-003 E.8) | The spec's rule; buttons follow the Mac's setting (CONVENTIONS.md, FM-006) |
| Not Doing: hiding with no way back; remembering the row's state | Proposed for docs/PRD.md, "Feature: Habits", Not Doing |
| Focus is taken back when rows leave the list | Test `testEscStillClosesAfterFoldingAwayTheFocusedStrip`; `AppModel.listDidHideRows`, wired in `PopoverController` |
| Manual look of the folded row | docs/manual-tests/habits.md, "Habit rows look right in every appearance" |
| Drift: `testCancellingTheDeleteConfirmationKeepsTheHabit` failed once, then passed 3/3 on its own; it now waits for the confirmation's Cancel to go before clicking the form's | Comment in that test |
