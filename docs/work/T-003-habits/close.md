# Close: T-003 Habits

| Item | Landed in |
| --- | --- |
| B.1–B.3 due days and schedule cut-over | Tests `habitIsDueOnlyOnScheduledWeekdaysFromTheDayItWasAdded`, `scheduleChangeAppliesFromTodayAndKeepsPastDays`, `secondScheduleChangeTheSameDayReplacesTheFirst`, `editingAHabitAddedTodayChangesItsOnlySchedule`, `addedOnGovernsWhenTheScheduleStartsLater`; ARCHITECTURE.md, State and Persistence |
| B.4–B.7 checking off, strip toggles, strips follow the month | Tests `togglingOnlyWorksOnDueDaysUpToToday`, `testCheckingOffTodayFillsTheButtonAndTodaysSquare`, `testFixingAMissedDayInTheStrip` |
| B.8–B.14 form | Tests `testAddingAHabitShowsItWithItsScheduleLabel`, `testAddIsDisabledWithoutADay`, `testTypingInTheNameFieldKeepsFocus`, `testReturnInTheNameFieldAddsTheHabit`, `testEditingAHabitRenamesItAndChangesItsDays`, `testEscapeInFormReturnsToList`, `testEscapeInNotesReturnsToList`, `droppingTodayFromTheScheduleRemovesTodaysCheckOff`, `draftNeedsANameAndADay`, `draftTrimsNameAndNote`, `newHabitsGoToTheBottomAndNamesMayRepeat` |
| B.15–B.17 delete and right-click | Tests `testDeletingAHabitAsksFirstThenRemovesIt`, `testCancellingTheDeleteConfirmationKeepsTheHabit`, `deletingAHabitRemovesItAndItsHistory`; ARCHITECTURE.md (native context menu) |
| B.18–B.20 saving, local dates, no network | Tests `testHabitsSurviveRelaunch`, `savedHabitsLoadBackUnchanged`, `saveReplacesTheFileWhole`; CONTRACTS.md; D-004, D-007 |
| E.1 scrolling | Manual "Many habits scroll inside the popover" (docs/manual-tests/habits.md) |
| E.2 discard on close | `AppModel.resetForOpen` clears the form; CONVENTIONS.md, Popover |
| E.3 rollover | Rows read `AppModel.today` (ARCHITECTURE.md) |
| E.4 limits | Tests `draftClampsNameAndNoteLength`, `testNameStopsAtFortyCharacters`; `HabitDraft.maxNameLength/maxNoteLength`; FM-010 |
| E.5 unreadable data | Tests `testUnreadableDataShowsMessageAndDisablesAdd`, `unreadableFileIsNeverOverwritten`, `newerFormatIsNeverOverwritten`, `saveBeforeLoadIsRefused`, and the strict-format tests |
| E.6 save failure | Manual "A failed save says so" |
| E.7 clock backward | Tests `checkOffsAfterTodayAreShownAsFuture`, `addedOnGovernsWhenTheScheduleStartsLater` |
| E.8 keyboard and VoiceOver (spec clarified: Tab with Keyboard navigation on; strip always) | Tests `testStripIsOneTabStopThatArrowsAndSpaceDrive`, `testHabitControlsHaveSpokenLabels`, `labelsDescribeEachDayAndButton`; manual "VoiceOver adjusts the strip day by day" |
| E.9 week start while editing | Day buttons use `WeekStart.orderedWeekdays` |
| §5 UI and labels | `HabitLabels`, `ScheduleLabel` + `scheduleLabelNamesCommonSchedulesAndListsOthersMondayFirst`; manual "Habit rows look right in every appearance" |
| §10 contract | CONTRACTS.md, "Saved habit data" |
| Design: components, data dir, cut-over, form state, context menu, rejected Codable-on-model and background saving | ARCHITECTURE.md |
| Design: form Esc, field limits, focus timing, form state | CONVENTIONS.md, Popover |
| Design: test seams and XCUITest notes | TESTING.md |
| Trap found: clamped field value | FM-010 |
| Intent and success criteria | docs/PRD.md, "Feature: Habits" and Done Means (already state it) |
| Deferred: drag to reorder, notes outside the form, undo for delete | BACKLOG.md: proposed, awaiting the customer's approval |
| Deferred: export and backup | Already in BACKLOG.md |
| Drift: data-dir seam, focus timing, row lookups | Commit messages aff120d, 9dd7d86, af353d3 |
