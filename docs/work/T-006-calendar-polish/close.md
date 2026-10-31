# Close: T-006 Calendar polish

| Item | Landed in |
| --- | --- |
| B.1 fixed, centered grid columns | `CalendarView.columns` doc comment |
| B.2 unchanged calendar behavior | Tests `gridAlwaysHasSixWeeksStartingOnWeekStart`, `testCalendarColumnsFollowTheMacsWeekStart`, `testPagingAcrossYearAndBackToToday`, `testPopoverOpensOnCurrentMonthAndListAndClosesOnSecondClick` |
| Not Doing: full date in the header | Dropped by the customer on 2026-10-30; the header must name the paged month. Recorded here and in commit 3ee6068 |
