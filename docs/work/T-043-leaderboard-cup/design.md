---
task: T-043
rigor: Simple
status: Approved
date created: 2026-11-24
---

# Tech Design: Leaderboard cup

## Summary

The cup today means only "perfect so far". It becomes "perfect so far, or on its best streak" (spec R1). The rule moves out of the view into HabitCalKit so it can be tested, and reuses `Streaks.isRecord`, so the leaderboard and the habit list agree on what a record streak is.

## Approach

- `Consistency.swift`: add `CupReason` (an OptionSet: `perfect`, `bestStreak`) and `Consistency.cup(tally:current:best:) -> CupReason`, plus `cupHelp(_:)` for the tooltip. Follows the existing pure helpers there (`percentText`, `streakText`).
- `LeaderboardScreen.swift`: `LeaderboardScreen` passes the best streak too (`Streaks.best`, as `HabitRow` does); `RankShield` takes a `CupReason` instead of `perfect: Bool`. One slice.

## Test Points

| Test | Kind | Spec rules proved |
| --- | --- | --- |
| cupForAPerfectRecordSoFar (and not for nothing due) | unit | R1b, R2 |
| cupForAHabitOnItsBestStreak (not at 1, not below best) | unit | R1a, R2 |
| cupHelpNamesWhatEarnedIt | unit | R3 |
| existing Consistency tests still pass | unit | R4 |
| Leaderboard shows the cup on the right rows | manual (next pass) | R1, R2 |

## Lasting Changes

| Change | Goes to |
| --- | --- |
| The cup rule (R1–R3) under Feature: Leaderboard | PRD.md |

## Reviewer Feedback

| Severity | Finding | Resolution |
| --- | --- | --- |
| MINOR | VoiceOver never heard the cup or why it was earned | Fixed: the row's spoken value ends with the cup's reason; voiceOverHearsWhyARowHasTheCup |
| IDEA | Add the best streak to the second detail line ("5 streak · best 5") | For the customer |
| IDEA | Give the cup shield an accessibility identifier so a UI test can check it | For the customer |
| IDEA | A different badge for "best streak" than for "perfect" | For the customer |
