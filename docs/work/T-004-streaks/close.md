# Close: T-004 Streaks

| Item | Landed in |
| --- | --- |
| B.1, B.2 current streak, today not breaking it | Tests `streakCountsOnlyDueDays`, `todayDoesNotBreakTheStreakBeforeItIsDone`; `Streaks.current` doc comment |
| B.3 best streak | Test `bestStreakIsTheLongestRunEver` |
| B.4 schedule in force per day | Test `streakRunsAcrossAScheduleChange` |
| B.5 ignore days before added and after today | Tests `streakIgnoresDaysBeforeAddedAndCheckOffsAfterToday`, `newHabitNotDueTodayHasNoStreak` |
| B.6, E.1, E.2 recompute immediately | Test `testCheckingOffUpdatesTheStreakImmediately`; computed on render (ARCHITECTURE.md) |
| E.3 deleted habit | Nothing stored; follows from the structure |
| E.4 spoken label | Test `streakSpokenLabelUsesDayAndDays` |
| Limits: hot at 3, no abbreviation | `Streaks.hotThreshold`; manual "Streaks show at the right of each row" |
| Design: `Streaks` component | ARCHITECTURE.md |
| Intent | docs/PRD.md, "Feature: Streaks" (already states it) |
