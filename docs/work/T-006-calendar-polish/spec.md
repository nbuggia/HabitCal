---
name: Calendar polish
task: T-006
status: Approved
last updated: 2026-10-30
---

# Spec: Calendar Polish

## 1. Summary

The month grid's days sit closer together, at the customer's request after using the app. Nothing else about the calendar changes.

## 3. Not Doing

- Today's full date in the header. The customer asked for it, then dropped it on 2026-10-30, because paging to another month still needs the header to name that month.

## 4. Current Behavior

- The grid's seven columns stretch across the popover's full width (T-002 implementation, flexible columns in `CalendarView`).

## 5. UI

- Grid: seven fixed columns about 32 pt wide with 2 pt between them, centered in the popover; rows 24 pt high with no extra spacing. Day numbers, the weekday initials row, today's circle, and the faint neighboring days are unchanged.

## 7. Behavior

### Changed

B.1 THE SYSTEM SHALL lay out the grid in fixed-width columns centered in the popover, not stretched across it. Was: flexible columns filling the width. Why: the days were too far apart.

### Unchanged

B.2 THE SYSTEM SHALL CONTINUE TO show six weeks in week-start order, with the header naming the displayed month ("October 2026"), paging, and spoken day labels. Covered by: `gridAlwaysHasSixWeeksStartingOnWeekStart`, `testCalendarColumnsFollowTheMacsWeekStart`, `testPagingAcrossYearAndBackToToday`, `testPopoverOpensOnCurrentMonthAndListAndClosesOnSecondClick`.
