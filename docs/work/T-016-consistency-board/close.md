# Close: T-016 Consistency board

| Item | Landed in |
| --- | --- |
| Summary and why (rank by share so schedules compete fairly) | Proposed for docs/PRD.md, a "Feature: Leaderboard" section; awaiting the customer's approval |
| B.1 share = done due days / due days | Test `shareCountsDueDaysCheckedOffInTheRange` |
| B.2 rolling windows ending today; all time from when added | Tests `rangesAreRollingWindowsEndingToday`, `allTimeStartsWhenTheHabitWasAdded` |
| B.3 today counts only once done | Test `todayCountsOnlyOnceDone`; doc comment on `Consistency.tally` |
| B.4 ranking, ties in order added, no due days last | Test `boardRanksByShareTiesKeepOrderAndNoDueDaysLast` |
| B.5 pooled score; 100% only for a perfect record | Tests `overallPoolsAllHabits`, `onlyAPerfectRecordShowsOneHundredPercent` |
| B.6 trophy opens on Past 7 days; Back and Esc return | UI test `testEscFromLeaderboardReturnsToList` (written, compiled; not yet run, at the customer's request) |
| B.7 switching range recomputes | UI test `testLeaderboardOpensRanksAndSwitchesRange` (written, compiled; not yet run) |
| B.8 spoken labels | Test `labelsReadPercentAndOrdinal`; UI tests above |
| B.9 every open resets to the list | Existing `testPopoverOpensOnCurrentMonthAndListAndClosesOnSecondClick` |
| UI: tabs, score card, rows, empty states | `LeaderboardScreen`; "No due days yet." per review finding 1 |
| Structure: `Consistency` in HabitCalKit, `LeaderboardScreen` | docs/engineering/ARCHITECTURE.md, HabitCalKit list and Views |
| Drift: custom tabs instead of a segmented Picker, which overflowed 260 pt | Doc comment on `LeaderboardScreen.rangePicker` |
