---
name: Menu bar date and month calendar slicing plan
task: T-002
design doc: docs/work/T-002-menubar-calendar/design.md
design doc version/commit: 1cfa4bb
date created: 2026-10-29
last updated: 2026-10-29
status: Approved
---

# Slicing Plan: Menu Bar Date and Month Calendar

## 0. Sliceability Gate

- Design conclusion: "Four slices; st-slice writes the plan. 1. Skeleton and FM-008 spike … 2. Icon and rollover … 3. Calendar … 4. Settings …" (§12)
- Design change required to slice: none

## 1. Rejected Alternative

Layer-first: all of HabitCalKit (Day, Month, MonthGrid, WeekStart, LaunchAtLoginPolicy) with its unit tests first, then the whole app. Rejected because it delays the riskiest unknowns (the hand-written project with a UI test target, and FM-008) behind a slice with no runnable demo.

## 2. Slices

### Slice 1: Skeleton and status-item spike

| Field               | Value |
| ------------------- | ----- |
| Status              | Done |
| Scope               | `HabitCal.xcodeproj` (hand-written, synchronized folders; app and UI-test targets; Debug bundle ID `com.muchfiner.HabitCal.debug`; LSUIElement; sandbox) and a shared `HabitCal` scheme. `HabitCalKit` package with `Day` and `TodaySource`. An app that shows a status item (a plain placeholder icon) and toggles an empty `.transient` popover through `PopoverController`, `PopoverHostingController`, and the 0.3 s debounce. Debug `LaunchOptions` with `-HabitCalDefaultsSuite`. |
| Demo criterion      | Unit: `dayFromDateUsesTheGivenCalendarsTimeZone`. UI: a spike test, `statusItemOpensAndClosesPopover`, that clicks the status item, finds the popover, and clicks again to close it; Slice 3 grows it into `popoverOpensOnCurrentMonthAndListAndClosesOnSecondClick`. Manual: no Dock icon or app-switcher entry (B.3); repeated ad-hoc rebuilds relaunch sandboxed without a container-access prompt. |
| Dependencies        | None: starts from the current repo (docs only). |
| Explicitly deferred | The real icon, rollover, the calendar, Esc, Settings, Quit, and the single-instance check (Slice 4, as the design orders it, so dev builds without Quit don't exit on each other). |
| Invalidation risk   | FM-008: if `statusItems` can't be clicked, switch to `-HabitCalOpenPopover`, record FM-008 as seen, and move `reopeningPopoverResetsToCurrentMonth` and the click-to-close step to the manual tests (design §12). If the hand-written project fails with the UI-test target or the package product, add the targets in Xcode once and commit the generated file; record it as drift. The UI tests need Accessibility/Automation permission for the test runner; if macOS prompts, the customer approves it once. |
| Size justification  | One outcome: a runnable, testable shell that every later slice extends. |
| Test gate           | Failing tests first at the design's test points (`swift test --package-path HabitCalKit`, then the area's XCUITests), then implement. |

### Slice 2: Icon and rollover

| Field               | Value |
| ------------------- | ----- |
| Status              | Done |
| Scope               | `MonthNames`, `MenuBarIcon` (template image, cut-out month, transparency layer), the status item's accessibility label, `-HabitCalToday` / `FixedTodaySource`, and `DayWatcher` (four notifications + 60 s timer) writing `model.today` and calling `refresh()`. `AppModel` with `today`. |
| Demo criterion      | UI: `menuBarIconShowsTodaysDate` with `-HabitCalToday 2026-10-29`. Manual, as the first entries in `docs/manual-tests/menu-bar.md`: icon at actual size in light, dark, tinted, and Increase Contrast (E.7); rollover across midnight, sleep through midnight, a clock change, and a time zone change (B.2). |
| Dependencies        | Slice 1's status item, `Day`, `TodaySource`, and launch options. |
| Explicitly deferred | Rollover while the popover is open (E.1), in Slice 3 once there's a calendar to update. |
| Invalidation risk   | If the `.destinationOut` cut-out can't render legibly at 18 pt (the letters fill in or blur at 1× and 2×), fall back to drawing the month in the bar's inverse with a knock-out mask image, and record it as design drift. Rollover is verified manually only (design §13). |
| Size justification  | The app's first job, the date, works end to end. |
| Test gate           | Failing tests first at the design's test points (`swift test --package-path HabitCalKit`, then the area's XCUITests), then implement. |

### Slice 3: Calendar

| Field               | Value |
| ------------------- | ----- |
| Status              | Pending |
| Scope               | `Month`, `MonthGrid`, `WeekStart.fromMac` / `resolve`, `macWeekStart` from `Calendar.autoupdatingCurrent` (+ locale-change observer and `-HabitCalMacFirstWeekday`). `CalendarView` with the header, ‹ / Today / ›, the 42-day grid, faint neighbors, today's circle, and spoken labels. The empty "Habits" area and the footer with the Settings gear (leading nowhere until Slice 4). `resetForOpen()`, `Screen` (`.list` only so far), `escape()`, and `cancelOperation` → `escape()` with `makeFirstResponder` after `show`. |
| Demo criterion      | Unit: `gridAlwaysHasSixWeeksStartingOnWeekStart`, `gridIncludesNeighbouringMonthDays`, `nextAndPreviousMonthCrossYearBoundaries`, `macFirstWeekdayMapsMondayToMondayAndOthersToSunday`. UI: `popoverOpensOnCurrentMonthAndListAndClosesOnSecondClick` (replacing Slice 1's spike test), `pagingAcrossYearAndBackToToday`, `reopeningPopoverResetsToCurrentMonth`, and `escapeFromListClosesPopover`, a new test point proving the `cancelOperation` path with nothing focused. Manual: rollover while open (E.1); changing the Mac's first weekday while running (B.12). |
| Dependencies        | Slice 2's `AppModel.today` and `DayWatcher`. |
| Explicitly deferred | Week-start override and Settings (Slice 4). The Settings half of Esc (`escapeLeavesSettingsThenClosesPopover`) is in Slice 4. |
| Invalidation risk   | If `escapeFromListClosesPopover` shows Esc never reaches `cancelOperation`, that's a DESIGN finding back to st-design (design finding 11), not a workaround here; Slice 4 is blocked until it's resolved. |
| Size justification  | The calendar job is complete: look up any month. |
| Test gate           | Failing tests first at the design's test points (`swift test --package-path HabitCalKit`, then the area's XCUITests), then implement. |

### Slice 4: Settings

| Field               | Value |
| ------------------- | ----- |
| Status              | Pending |
| Scope               | `SettingsView` with About, the link, Week starts on (override rules, "Use Mac setting"), and Launch at login (`LoginItem`, `LaunchAtLoginPolicy`, state mapping with the policy first, the approval caption, the disabled-outside-/Applications caption). Launch policy at startup (B.17). `MainMenu` with ⌘Q and the Quit button. Single-instance check (E.2). `Screen.settings` with Back, and Esc from Settings. |
| Demo criterion      | Unit: `pickingMacDayWithoutOverrideKeepsFollowingMac`, `pickingWhileOverriddenKeepsOverride`, `pickingOtherDayOverrides`, `launchAtLoginRegistersOnlyFirstLaunchFromApplications`, `onlyTheApplicationsFolderCountsAsInstalled`. UI: `escapeLeavesSettingsThenClosesPopover`, `settingsBackKeepsDisplayedMonth`, `overridingWeekStartReordersCalendarAndPersists`, `macWeekStartIsUsedUntilOverridden`, `quitButtonAndCommandQQuit`, `controlsHaveSpokenLabels`. Manual: Launch at login checks (B.16, B.17, E.3–E.5, E.9, E.10); second copy exits (E.2); the link opens the browser (B.18); VoiceOver and Tab with Keyboard navigation on (E.6). Then the whole `menu-bar.md` and the full test suite run once, including Slice 2's `menuBarIconShowsTodaysDate` as a regression. |
| Dependencies        | Slice 3's `Screen`, `escape()`, calendar, and gear. |
| Explicitly deferred | Signed-build login-item retest (T-005). |
| Invalidation risk   | `SMAppService` with ad-hoc signing may report differently than a signed build; the manual tests record what was seen, and T-005 repeats them. |
| Size justification  | Completes the spec: Settings, Quit, and launch at login. |
| Test gate           | Failing tests first at the design's test points (`swift test --package-path HabitCalKit`, then the area's XCUITests), then implement. |

## 3. Review Findings

Severities and decisions: `.steel-thread/framework/reviews.md`.

| #   | Finding | Category | Severity | Decision | Slices | Rationale | Next step |
| --- | ------- | -------- | -------- | -------- | ------ | --------- | --------- |
| 1 | No Esc test in Slice 3, though its risk depends on one | SLICING | MAJOR | ACCEPT | 3, 4 | A DESIGN failure would surface a slice late | New test point `escapeFromListClosesPopover` in Slice 3 |
| 2 | Slice 2's demo never exercises DayWatcher | SLICING | MAJOR | ACCEPT | 2 | B.2 is the app's first job | Manual rollover checks in Slice 2's demo |
| 3 | Manual tests lumped into Slice 4 | SLICING | MINOR | ACCEPT | 1–4 | Verify where built | Each manual check assigned to its slice |
| 4 | Single instance moved to Slice 1 without a record | SLICING | MINOR | ACCEPT | 1, 4 | Dev builds without Quit would exit | Kept in Slice 4, per the design |
| 5 | `-HabitCalToday` unused in Slice 1; empty Habits area unassigned | SLICING | MINOR | ACCEPT | 1–3 | Scope hygiene | Moved to Slice 2; Habits area in Slice 3 |
| 6 | Vague invalidation risk in Slice 2 | SLICING | MINOR | ACCEPT | 2 | Not a falsifiable condition | Named the condition and the fallback |
| 7 | Test points not named per slice; duplicates | SLICING | MINOR | ACCEPT | 1–4 | Ambiguous ownership | Every test named once; Slice 1 spike test grows in Slice 3 |

## 4. Dependency Graph

Slice 1 → Slice 2 → Slice 3 → Slice 4

## 5. Checkpoint Log

### After Slice 1

- Commit: the "T-002 slice 1" commit following 899eed8.
- Affected remaining slices reviewed: 2, 3, and 4. The FM-008 spike passed (`statusItems` can be clicked), so the `-HabitCalOpenPopover` fallback isn't needed, and `reopeningPopoverResetsToCurrentMonth` and click-to-close stay automated. The hand-written project worked with the UI-test target and the package product, so there's no drift.
- Changed: added a `.swift-format` config (4-space indent, 120 columns), because the formatter's 2-space default fought Xcode's style. XCTest UI tests need `@MainActor` on the class and async `setUp`/`tearDown` under Swift 6. Slices 2–4 follow both.

### After Slice 2

- Commit: the "T-002 slice 2" commit.
- Affected remaining slices reviewed: 3 (it uses `AppModel`, `MonthNames`, and `DayWatcher`; all three are in place). Slice 4 is unchanged.
- Changed: `StatusItemController.refresh()` became `show(_ day:)`, taking the day explicitly. That's the same mechanism (DayWatcher calls it directly) with clearer data flow. `Day.weekday` and `MonthNames.spokenDate` are in HabitCalKit, so the icon's spoken label is unit-tested. The `.destinationOut` cut-out renders cleanly at 18 pt (checked with an 8× render in light and dark), so the Slice 2 fallback isn't needed. The manual tests (icon look, rollover) are written and need the customer's eyes and real time.

## 6. Design Drift

| Change | Affected slices | Reevaluation |
| ------ | --------------- | ------------ |
