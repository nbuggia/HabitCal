# Close: T-022 Select a day

| Item | Landed in |
| --- | --- |
| Summary and why | Proposed for docs/PRD.md, "Feature: Month Calendar"; awaiting the customer's approval |
| B.1 clicking a day selects it; neighboring months page | `AppModel.select`; UI test `testSelectingAPastDayShowsAndFixesItsHabits` (written, compiled, not yet run) |
| B.2 selected solid square; today pale | `DayCell`; docs/manual-tests/menu-bar.md, "Selecting a day across midnight, and its markers" |
| B.3 list shows habits due on the selected day | `HabitListScreen` uses `shownDay`; test `listLabelsFollowTheSelectedDay`; UI test above |
| B.4 done buttons check off a past selected day | `AppModel.toggleShownDay`; tests `doneButtonLabelsNameTheSelectedDay`, `testSelectingAPastDayShowsAndFixesItsHabits` |
| B.5 future days read-only | `DoneButton` disabled; `Habits.toggle` refuses; UI test `testFutureDayIsReadOnlyAndTodayButtonReturns` |
| B.6 Today button selects today | `AppModel.showToday`; same UI test |
| B.7 every open selects today | `AppModel.resetForOpen`; UI test `testReopeningSelectsToday` |
| B.8 midnight follows today; another selection stays | `selectedDay` nil means today; manual test above |
| B.9 spoken labels | Tests `spokenCalendarDayMarksTheSelection`, `listLabelsFollowTheSelectedDay` |
| B.10 strips and streaks unchanged | Existing tests |
| Structure: the list follows `shownDay` | docs/engineering/ARCHITECTURE.md, The Popover |
| T-012 B.4 with a selected day | `AppModel.saveForm`; UI test `testAddingAHabitWhileAPastDayIsSelectedKeepsItInView` |
| Deferred: grid as one Tab stop | Proposed for BACKLOG.md (pickup.md); TESTING.md notes the Tab-loop assumption |
