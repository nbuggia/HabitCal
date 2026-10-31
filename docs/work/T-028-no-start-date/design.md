---
task: T-028
rigor: Simple
status: Approved
date created: 2026-10-30
---

# Tech Design: No Start Date

## Summary

`Habit.days(on:)` drops its `day >= addedOn` guard. The day walks in `Streaks` and `Consistency` were bounded by `addedOn`; they now start at `Habit.trackedFrom(today:)`, the earliest check-off (or today when there's none), which is where a streak can first begin. All time uses the earlier of `addedOn` and that day. No change to habits.json.

## Approach

- `Habit.swift`: `days(on:)` without the guard; `public func trackedFrom(today: Day) -> Day` = `min(checkOffs.min() ?? today, today)`.
- `Streaks.swift`: `current` walks back while `day >= trackedFrom`; `best` walks forward from `trackedFrom`.
- `Consistency.swift`: the walk starts at the range's start, or for All time at `min(addedOn, trackedFrom)`; no clamp to `addedOn`.
- Rename and rewrite the tests that encoded the old rule.

## Test Points

| Test (named for the behavior it proves) | Kind | Spec rules proved |
| --- | --- | --- |
| `habitIsDueOnEveryScheduledWeekdayBeforeAndAfterItWasAdded` | unit | B.1 |
| `beforeTheFirstScheduleEntryTheFirstEntryApplies` | unit | B.1 |
| `pastDaysBeforeAddedCanBeCheckedOff` | unit | B.2 |
| `streakCountsCheckOffsBeforeTheHabitWasAddedButNotAfterToday` | unit | B.3, B.5 |
| `allTimeStartsAtTheEarlierOfAddedAndFirstCheckOff`, updated range tests | unit | B.4 |
| Updated `LeaderboardUITests` expectations (Push-ups' 30-day share) | UI (next full run) | B.4 |

## Lasting Changes

| Change | Goes to |
| --- | --- |
| "Due day" no longer starts when the habit was added | Proposed for docs/CONTEXT.md, Vocabulary |
| Streak and leaderboard walks start at `trackedFrom` | Doc comments in `Streaks`, `Consistency` |

## Review Findings

| # | Severity | Finding | Decision | Source |
| --- | --- | --- | --- | --- |
| 1 | MAJOR | A schedule edit on the day a habit was added replaced its only entry, so the new schedule applied to every past day and could drop past check-offs | ACCEPT: `Habits.update` pins the old days to the past with an entry from yesterday; `scheduleEditOnTheDayAddedKeepsPastDaysOnTheOldSchedule` | Pass 1 |
| 2 | MINOR | Stale comments on `addedOn` and `add` | ACCEPT | Pass 1 |
| 3 | MINOR | Strip states before the habit was added untested | ACCEPT: `stripShowsDaysBeforeAddedAsMissedOrDone` | Pass 1 |
| 4 | MINOR | Walks start at the oldest check-off, which a stray check-off can put years back | Accepted risk: check-offs before today come only from the strip or a selected day, a month at a time; a walk of a few thousand days is still milliseconds | Pass 1 |
| 5 | QUESTION | A brand-new habit scores 0% in the rolling windows, and the tests moved to All time hid it | ACCEPT: the customer's rule (no start date) implies it; `rollingWindowCountsDaysBeforeAHabitWasAdded` names it | Pass 1 |
