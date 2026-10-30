---
task: T-004
rigor: Simple
status: Approved
date created: 2026-10-29
---

# Tech Design: Streaks

## Summary

Adds `Streaks` to HabitCalKit: current and best streak computed from T-003's `Habit.isDue` and check-offs. It walks every day from `addedOn` to today, so past days are judged by the schedule in force then (B.4), and days before the habit was added or after today are ignored (B.5). It's a pure function of the habit and today, so it recomputes on every render (B.6, E.1–E.2), with no cache or saved state. `HabitRow` shows both numbers on the right with Phosphor fire and trophy icons; the fire turns flame-orange at 3 or more. Settled scope: the spec as written; nothing deferred.

## Approach

- `HabitCalKit/Sources/HabitCalKit/Streaks.swift`: `Streaks.current(_ habit: Habit, today: Day) -> Int` walks back from today, skipping days that aren't due and skipping today if it isn't done yet (B.1, B.2). `Streaks.best(_:today:)` walks forward from `addedOn`, and a due day that isn't done breaks the run, except today (B.3). `Streaks.hotThreshold = 3`. `Streaks.spoken(current:best:)` returns "Current streak 12 days, best streak 30 days" (E.4). This follows the existing pattern of HabitCalKit enums (`MonthGrid`, `ScheduleLabel`).
- `HabitCal/Views/HabitRow.swift`: two `StreakStat` views after the `Spacer`, with tooltips "Current streak" and "Best streak", combined into one accessibility element with the spoken label.
- Cost: a habit held for 3 years is about 1,100 days per walk, twice per row per render. That's negligible next to drawing the strip.
- One slice.

## Test Points

| Test (named for the behavior it proves) | Kind (unit / integration / UI / manual) | Spec rules proved |
| --- | --- | --- |
| `streakCountsOnlyDueDays` (the spec's examples table, rows 1 and 3) | unit | B.1, UC-2 |
| `todayDoesNotBreakTheStreakBeforeItIsDone` (row 2) | unit | B.2, E.2 |
| `bestStreakIsTheLongestRunEver` (rows 4 and 5) | unit | B.3 |
| `newHabitNotDueTodayHasNoStreak` (row 6) | unit | B.5, §5 zero |
| `streakRunsAcrossAScheduleChange` | unit | B.4, E.1 |
| `streakIgnoresDaysBeforeAddedAndCheckOffsAfterToday` | unit | B.5 |
| `streakSpokenLabelUsesDayAndDays` | unit | E.4 |
| `checkingOffUpdatesTheStreakImmediately` | UI | B.6, UC-1, UC-3, §5 |
| Hot color at 3+, large numbers unabbreviated | manual (docs/manual-tests/habits.md) | Limits, §5 |

E.3 (a deleted habit's streaks go with it) follows from the structure: streaks are computed from the habit, so there's nothing stored to delete.

## Lasting Changes

| Change | Goes to |
| --- | --- |
| `Streaks` in the HabitCalKit component list | ARCHITECTURE.md |
| Streak intent | PRD "Feature: Streaks" (already states it) |
