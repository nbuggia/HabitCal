# Close: T-015 Prototype a leaderboard of progress across all habits

A prototype task: it answered a question and T-016 built the answer.

| Item | Landed in |
| --- | --- |
| Chosen: Consistency, habits ranked by share of due days done | T-016; `Consistency` in HabitCalKit, test `boardRanksByShareTiesKeepOrderAndNoDueDaysLast` |
| Chosen: range tabs Past 7 days · Past 30 days · All time, rolling windows ending today | Tests `rangesAreRollingWindowsEndingToday`, `ConsistencyTests` range titles; UI test `testLeaderboardOpensRanksAndSwitchesRange` |
| Chosen: opens from a trophy button in the Habits header row, Back returns | `HabitListScreen` header button "Leaderboard"; UI test `testEscFromLeaderboardReturnsToList` |
| Rejected: Streak Board (rank by current streak) and This Week (seven-day dots) | Proposed for docs/PRD.md "Feature: Leaderboard", Not Doing; awaiting the customer's approval with T-016's section |
