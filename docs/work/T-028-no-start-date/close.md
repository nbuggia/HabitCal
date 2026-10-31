# Close: T-028 No start date

| Item | Landed in |
| --- | --- |
| B.1 due on scheduled days before the habit was added; first entry applies before it starts | Tests `habitIsDueOnEveryScheduledWeekdayBeforeAndAfterItWasAdded`, `beforeTheFirstScheduleEntryTheFirstEntryApplies`; `Habit.days(on:)` doc comment |
| B.2 past days before added can be checked off and show done or missed | Tests `pastDaysBeforeAddedCanBeCheckedOff`, `stripShowsDaysBeforeAddedAsMissedOrDone` |
| B.3 streaks walk from the first check-off | Test `streakCountsCheckOffsBeforeTheHabitWasAddedButNotAfterToday`; `Habit.trackedFrom` |
| B.4 All time from the earlier of added and first check-off; rolling windows count every due day | Tests `allTimeStartsAtTheEarlierOfAddedAndFirstCheckOff`, `rollingWindowCountsDaysBeforeAHabitWasAdded`; `LeaderboardUITests` (next full run) |
| B.5 past days keep the schedule in force then, even after an edit on the day added | Test `scheduleEditOnTheDayAddedKeepsPastDaysOnTheOldSchedule`, `editingAHabitAddedTodayChangesItFromTodayOn`; comment in `Habits.update` |
| Vocabulary: "Due day" no longer starts when the habit was added | Proposed for docs/CONTEXT.md (pickup.md) |
| Accepted risk: walks start at the oldest check-off | Design, Review Findings 4 |
