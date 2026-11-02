---
task: T-041
rigor: Simple
status: Approved
date created: 2026-11-01
---

# Tech Design: Due-Day Strip

## Summary

The strip becomes 30 rounded squares of the habit's due days, ending at the shown day (marked), oldest on the left. Days before the habit was added are faint unless done. It isn't clickable, takes no focus, and is hidden from VoiceOver (spec B.1–B.9a, E.1–E.5). Scope as the approved spec. Simple: no saved format, contract, component, or concurrency change, and every rule is unit-testable.

## Approach

- **HabitCalKit, `Habit.swift`:** `Habit.dueStrip(endingAt: Day, today: Day) -> [DueSquare?]` replaces `strip(for:today:)`. It walks back from the shown day one day at a time, at most 1,096 days (three years, E.5), keeps days where `isDue(on:)` (so B.21 check-offs count, B.2), stops at 30, reverses them, and pads the front with nil (blank slots). `DueSquare` holds `day`, `state` (`done`, `missed`, `beforeAdded`, `future`), and `isShown` (the newest). The state is `future` when after today, else `done` when done, else `beforeAdded` before `addedOn`, else `missed`. `StripDay` and `strip(for:)` are removed with their only users.
- **`HabitLabels`:** `stripTooltip(_ square: DueSquare)` gives "Oct 5 · done / missed / before added", or just the date for future. `stripSpoken` is removed (B.7).
- **`StripView`:** a plain `HStack` of 30 `StripSquare`s from `habit.dueStrip(endingAt: model.shownDay, today: model.today)`, with `.help` tooltips and `.accessibilityHidden(true)`. No focus, key handlers, cursor, or tap (B.6, B.7). The ring goes on `isShown` (B.3, B.9a). `beforeAdded` uses today's not-scheduled grey (B.5a); a blank slot is clear. The squares keep `aspectRatio(1)` and `frame(maxWidth: .infinity)`, so 30 fill the same width.
- **Tests:** the kit `stripShows…` tests are rewritten for `dueStrip`, and the UI tests listed in the spec's Removed section are removed or rewritten.

## Test Points

| Test (named for the behavior it proves) | Kind | Spec rules proved |
| --- | --- | --- |
| `dueStripShowsLast30DueDaysOldestFirst` (a M/W/F habit) | unit | B.1, B.2, B.9, Limits |
| `dueStripEndsAtTheShownDayMarked` (today and a selected past day) | unit | B.3, B.9a, UC-2 |
| `dueStripShowsDueDaysAfterTodayAsFuture` | unit | B.4 |
| `dueStripShowsDaysBeforeAddedFaintUnlessDone` | unit | B.5a, B.10 |
| `dueStripKeepsPastDaysOnTheScheduleThenInForce` | unit | E.2 |
| `dueStripIncludesACheckOffOnAnUnscheduledDay` | unit | B.2 (T-039 B.21) |
| `dueStripLeavesBlankSlotsWhenFewerThan30DueDaysExist` | unit | E.5 |
| `stripTooltipsNameTheDayAndState` | unit | B.5 |
| `testSelectingAPastDayShowsAndFixesItsHabits` (existing) | UI | B.11, UC-3 |
| Rewritten: `testCheckingOffTodayFillsTheButtonAndTodaysSquare` → `testCheckingOffTodayFillsTheButton`, `testHabitControlsHaveSpokenLabels`, `testCheckingOffUpdatesTheStreakImmediately` | UI | B.12, E.1 |
| Manual: the strip in light, dark, and Increase Contrast; ring on the shown day; faint before-added squares; nothing happens on click; VoiceOver skips it | manual | B.6, B.7, §5 |

## Risks

- FM-002: days stay `Day`; the walk uses `Day.adding(days:)`.
- FM-006: the strip no longer takes focus, so a row leaving the list can't strand focus there. `testEscStillClosesAfterTheFocusedStripLeavesTheList` goes with the focus it tested.

## Lasting Changes

| Change | Goes to |
| --- | --- |
| The strip is `Habit.dueStrip`: 30 due days ending at the shown day, three-year search cap, before-added faint; display only | ARCHITECTURE.md (The Popover) |
| Manual test changes (habits.md) | docs/manual-tests/habits.md |
