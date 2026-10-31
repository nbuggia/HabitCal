---
task: T-022
rigor: Simple
status: Approved
date created: 2026-10-30
---

# Tech Design: Select a Day

## Summary

`AppModel` gains `selectedDay: Day?`, where nil means "today", so a midnight rollover moves the selection on its own (B.8). `shownDay` (`selectedDay ?? today`) replaces `today` wherever the habit list asks "which day?": the due/not-due split, the done buttons, and the labels. Streaks, strips, and the leaderboard keep using `today`. Day cells become buttons. The new wording lives in HabitCalKit, so it's unit-tested.

## Approach

- `HabitCalKit/Sources/HabitCalKit/HabitLabels.swift`:
  - `doneButtonSpoken(name:dueToday:doneToday:)` and `doneButtonTooltip(...)` gain a `day:`/`today:` pair. On today they read as now. On a past day: "Push-ups, done on October 23" / "Push-ups, not done on October 23" / "Mark done for Oct 23" / "Done Oct 23 — click to undo". On a future day: "Can't check off a future day".
  - `notDueRowTitle(count:onToday:)` gives "3 not due today" or "3 not due that day"; `notDueRowSpoken` follows.
  - `listHeader(day:today:)` gives nil on today, or "FRI, OCT 23".
  - `nothingDue(onToday:)` gives "Nothing due today" or "Nothing due that day".
- `HabitCalKit/Sources/HabitCalKit/MonthNames.swift`: `spokenCalendarDay(_:isToday:isSelected:)`, adding ", selected".
- `HabitCal/AppModel.swift`:
  - `private(set) var selectedDay: Day?` and `var shownDay: Day`.
  - `select(_ day: Day)` stores nil for today. A day outside the displayed month pages to its month.
  - `showToday()` and `resetForOpen()` clear the selection (B.6, B.7).
  - `toggleShown(_ id:)` replaces `toggleToday`, using `toggle(id, on: shownDay)`; `Habits.toggle` already refuses future and not-due days (B.5).
- `HabitCal/Views/CalendarView.swift`: `DayCell` takes `isSelected` and becomes a `Button` with `.hover(cornerRadius: 4.7)`. Solid square when selected; pale square with an accent-colored number for today when not selected (B.2).
- `HabitCal/Views/HabitListScreen.swift`: the split, "Nothing due…", and the folded row use `model.shownDay`; the header shows `listHeader` after "HABITS".
- `HabitCal/Views/HabitRow.swift`: `DoneButton` reads `model.shownDay`; on a future day it's disabled.

## Test Points

| Test (named for the behavior it proves) | Kind (unit / integration / UI / manual) | Spec rules proved |
| --- | --- | --- |
| `doneButtonLabelsNameTheSelectedDay` | unit | B.4, B.5, B.9 |
| `listLabelsFollowTheSelectedDay` | unit | B.3, §5 |
| `spokenCalendarDayMarksTheSelection` | unit | B.9 |
| `testSelectingAPastDayShowsAndFixesItsHabits` | UI (written; run with the next full suite) | B.1, B.3, B.4 |
| `testFutureDayIsReadOnlyAndTodayButtonReturns` | UI (written; run with the next full suite) | B.5, B.6 |
| `testReopeningSelectsToday` | UI (written; run with the next full suite) | B.7 |
| Midnight with today selected, and with another day selected | manual: docs/manual-tests/menu-bar.md | B.8 |
| Light and dark: selected square and today's pale square | manual: docs/manual-tests/menu-bar.md | B.2 |

## Lasting Changes

| Change | Goes to |
| --- | --- |
| The list follows `AppModel.shownDay`; streaks and strips follow `today` | ARCHITECTURE.md, The Popover |
| Day selection | Proposed for PRD.md, "Feature: Month Calendar" |

## Review Findings

| # | Severity | Finding | Decision | Source |
| --- | --- | --- | --- | --- |
| 1 | MAJOR | A habit saved while a past day was selected vanished into the closed folded row (`saveForm` checked today, the list the shown day) | ACCEPT: `saveForm` checks `shownDay`; `testAddingAHabitWhileAPastDayIsSelectedKeepsItInView` | Pass 1 |
| 2 | MINOR | A not-due habit on a future day said "can't check off a future day" | ACCEPT: not-scheduled checked first; `aFutureDayThatIsNotDueSaysNotScheduled` | Pass 1 |
| 3 | MINOR | With Keyboard navigation on, 42 day buttons become Tab stops before the list | DEFER: TESTING.md notes the Tab-loop tests assume it's off; backlog row proposed (grid as one arrow-key stop, like the strip) | Pass 1 |
| 4 | QUESTION | Header's spoken label abbreviated ("FRI, OCT") | ACCEPT: `listHeaderSpoken`, "Habits, Friday, October 23" | Pass 1 |
