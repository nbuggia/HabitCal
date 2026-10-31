---
task: T-016
rigor: Simple
status: Approved
date created: 2026-10-30
---

# Tech Design: Consistency Board

## Summary

A pure `Consistency` type in HabitCalKit computes each habit's done and due counts over a range and ranks them, with labels for the rows and score. The app gains a `.leaderboard` screen: `AppModel` opens and closes it and holds the chosen range, and `LeaderboardScreen` draws it from `Consistency.board(...)`. Nothing is stored.

## Approach

- `HabitCalKit/Sources/HabitCalKit/Consistency.swift`:
  - `public enum ConsistencyRange: CaseIterable { case past7, past30, allTime }` with `title` ("Past 7 days", …).
  - `public struct ConsistencyTally: Equatable { done: Int; due: Int; share: Double? }`, where `share` is nil when `due == 0`.
  - `public struct ConsistencyEntry { habit: Habit; tally: ConsistencyTally }`.
  - `public enum Consistency`:
    - `tally(_ habit:, range:, today:)` walks the days from the range's start (today − 6, today − 29, or `habit.addedOn`, never before `addedOn`) through today. A day counts as due if `habit.isDue(on:)`, except today, which counts only once it's done (B.3).
    - `board(_ habits: [Habit], range:, today:) -> [ConsistencyEntry]` sorts by share, highest first, with a stable sort so ties keep the order added, and nil shares last (B.4).
    - `overall(_ entries:) -> ConsistencyTally` sums done and due (B.5).
    - `percentText(_ tally:) -> String` returns "93%" or "—"; `rowSpoken(rank:name:tally:)` returns "1st, Read, 93 percent"; `scoreSpoken(_ tally:)` returns the score's label (B.8). Ordinals come from `NumberFormatter` with the `.ordinal` style in `en_US`, since the app is English-only (T-002).
- `HabitCal/AppModel.swift`: `Screen.leaderboard`; `private(set) var leaderboardRange: ConsistencyRange = .past7`; `openLeaderboard()` sets the range to `.past7` and the screen; `closeLeaderboard()`; `pickLeaderboardRange(_:)`; `escape()` handles `.leaderboard` like `.settings`.
- `HabitCal/Views/LeaderboardScreen.swift`: the header like `SettingsScreen.header`; three equal-width tab buttons (`RangeTab`: caption text, accent fill when selected, a soft highlight on hover) on a light track. Drift: a segmented `Picker` was built first, but it won't shrink below its labels, and at 260 pt it overflowed and pushed the whole screen against the popover's edges (the customer's bug 8); the score card styled like the Settings card (`.quaternary.opacity(0.5)`, 8 pt corners); the rows in a `ScrollView` capped like the habit list. The bar is a `Capsule` track with an accent-color fill, 5 pt tall.
- `HabitCal/Views/PopoverRoot.swift`: route `.leaderboard`.
- `HabitCal/Views/HabitListScreen.swift`: the trophy button between the Spacer and Settings, sharing a helper with Settings for the 22 pt target.

## Test Points

| Test (named for the behavior it proves) | Kind (unit / integration / UI / manual) | Spec rules proved |
| --- | --- | --- |
| `shareCountsDueDaysCheckedOffInTheRange` | unit | B.1, B.2 |
| `rangesAreRollingWindowsEndingToday` | unit | B.2 |
| `allTimeStartsWhenTheHabitWasAdded` | unit | B.2 |
| `todayCountsOnlyOnceDone` | unit | B.3 |
| `boardRanksByShareTiesKeepOrderAndNoDueDaysLast` | unit | B.4 |
| `overallPoolsAllHabits` | unit | B.5 |
| `labelsReadPercentAndOrdinal` | unit | B.5, B.8 |
| `onlyAPerfectRecordShowsOneHundredPercent` | unit | B.5 |
| `testLeaderboardOpensRanksAndSwitchesRange` | UI (written; run with the next full suite) | B.6, B.7 |
| `testEscFromLeaderboardReturnsToList` | UI (written; run with the next full suite) | B.6 |

## Lasting Changes

| Change | Goes to |
| --- | --- |
| `Consistency` in HabitCalKit; the `.leaderboard` screen | ARCHITECTURE.md, HabitCalKit list and The Popover |
| Leaderboard feature | Proposed for PRD.md, a "Feature: Leaderboard" section |

## Review Findings

| # | Severity | Finding | Decision | Source |
| --- | --- | --- | --- | --- |
| 1 | MINOR | Habits with nothing due yet showed "— of due days done", and VoiceOver said something different | ACCEPT: "No due days yet." in the card; spec §5 | Pass 1 |
| 2 | QUESTION | Rounding showed 100% for a record with misses, contradicting the ranking | ACCEPT: 100% only for a perfect record, 0% only for none done; B.5; `onlyAPerfectRecordShowsOneHundredPercent` | Pass 1 |

An earlier review attempt failed on a network error before reporting; Pass 1 is the rerun.
