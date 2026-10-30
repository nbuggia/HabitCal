# Close: T-002 Menu bar date and month calendar

| Item | Landed in |
| --- | --- |
| B.1 icon shows today's month and day | Test `testMenuBarIconShowsTodaysDate`; `MenuBarIcon` |
| B.2 rollover within a minute (midnight, wake, clock, time zone) | `DayWatcher` doc comment; docs/manual-tests/menu-bar.md, rollover checks; FM-001 |
| B.3 no Dock icon | `INFOPLIST_KEY_LSUIElement`; manual test "HabitCal has no Dock icon or app-switcher entry" |
| B.4 each open starts on the list and current month | Test `testReopeningPopoverResetsToCurrentMonth`; ARCHITECTURE.md, "The Popover" |
| B.5 icon click / outside click / Esc order | Tests `testPopoverOpensOnCurrentMonthAndListAndClosesOnSecondClick`, `testEscapeFromListClosesPopover`, `testEscapeLeavesSettingsThenClosesPopover`; manual "Clicking outside closes the popover"; CONVENTIONS.md, Popover |
| B.6–B.10 grid, today circle, paging, no limit | Tests `gridAlwaysHasSixWeeksStartingOnWeekStart`, `gridIncludesNeighbouringMonthDays`, `nextAndPreviousMonthCrossYearBoundaries`, `testPagingAcrossYearAndBackToToday`; `MonthGrid.dayCount` |
| B.11 Settings and Back | Test `testSettingsBackKeepsDisplayedMonth` |
| B.12 week start follows the Mac | Tests `macFirstWeekdayMapsMondayToMondayAndOthersToSunday`, `testCalendarColumnsFollowTheMacsWeekStart`; manual "The calendar follows the Mac's first day of the week" |
| B.13–B.15 override rules and persistence | Tests `pickingMacDayWithoutOverrideKeepsFollowingMac`, `pickingWhileOverriddenKeepsOverride`, `pickingOtherDayOverrides`, `testOverridingWeekStartReordersCalendarAndPersists`, `testMacWeekStartIsUsedUntilOverridden`, `weekdaysAreOrderedFromTheWeekStart` |
| B.16, B.17, E.3–E.5, E.9, E.10 launch at login | Tests `launchAtLoginRegistersOnlyFirstLaunchFromApplications`, `onlyTheApplicationsFolderCountsAsInstalled`, `testLaunchAtLoginIsDisabledOutsideApplications`; manual launch-at-login checks; FM-009 |
| B.18 link opens browser and closes popover | CONTRACTS.md, "About link"; manual "The website link opens the browser" |
| B.19 Quit and ⌘Q | Tests `testQuitButtonQuits`, `testCommandQQuitsWhilePopoverIsOpen`; CONTRACTS.md, "⌘Q quits" |
| E.1 rollover while open | Manual "Today's circle moves at midnight while the popover is open" |
| E.2 single instance | `AppDelegate` comment; manual "A second copy exits" |
| E.6 keyboard and VoiceOver | Tests `testControlsHaveSpokenLabels`, `spokenFullDateIncludesTheYear`; manual "Keyboard and VoiceOver reach every control" |
| E.7 appearance | Manual "The icon is legible at actual size in every menu bar appearance" |
| E.8 crowded menu bar | Dropped: accepted in the spec, nothing to build |
| Limits: 42 cells, 1-minute staleness, Sun/Mon only | `MonthGrid.dayCount`, `DayWatcher.fallbackInterval`, `WeekStart` |
| Design: components, bundle IDs, project file, defaults keys, popover/Esc mechanics | docs/engineering/ARCHITECTURE.md |
| Design: Esc rule, screen extension, no doubled labels, folder-synced files | docs/engineering/CONVENTIONS.md |
| Design: launch options, XCUITest notes, confirmed commands | docs/engineering/TESTING.md |
| FM-006 example, FM-008 outcome | docs/engineering/COMMON-FAILURE-MODES.md |
| Rejected: MenuBarExtra | D-005 |
| Rejected: XcodeGen/Tuist; `.onKeyPress` for Esc | ARCHITECTURE.md, Stack; CONVENTIONS.md, Popover |
| Spec summary and intent | docs/PRD.md, "Feature: Menu Bar Date" and "Feature: Month Calendar" (already state it; unchanged) |
| Success criteria | docs/PRD.md, Done Means (already listed) |
| Deferred: ←/→ month shortcuts, global hotkey, localization, week numbers | BACKLOG.md: proposed, awaiting the customer's approval (pickup.md, Proposed Updates) |
| Drift: `show(_:)` instead of `refresh()`; first-launch default in AppModel; extra tests | Commit messages c7056b2, 3892268, 549073b |
