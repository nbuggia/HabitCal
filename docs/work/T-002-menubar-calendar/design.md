---
name: Menu bar date and month calendar
description: Creates the Xcode project, the HabitCalKit package, and the app shell: menu bar icon, popover, month calendar, and Settings.
task: T-002
rigor: Complex
trigger: "structure: adds the app's first components (app target, HabitCalKit package, UI test target); also permissions (SMAppService) and timing (day rollover)"
date: 2026-10-29
review iteration: 2
status: Approved
---

# Tech Design: Menu Bar Date and Month Calendar

## 1. Context

There's no code yet. T-002 creates the project and everything T-003 and T-004 build on: the app target, the HabitCalKit package, the UI test target, the status item and popover, the "today" source, and Settings. The spec (Approved; E.10 added during this design) defines the behavior. ARCHITECTURE.md, D-005, and D-007 fix the shape.

## 2. Goals / Non-Goals

Goals:
- Every T-002 spec rule has a test point or a manual check (§13).
- `swift test --package-path HabitCalKit` and `xcodebuild test -scheme HabitCal` both run green from a clean checkout. This confirms the TESTING.md commands.
- The "today" source and the popover's screen model are the ones T-003 extends. T-003 adds a screen and a store without reshaping them.

Non-goals:
- Habits, the data file, and streaks. The popover shows the calendar, an empty "Habits" area, and the footer gear; T-003 fills in the rest, including "+ Add habit".
- Signing with a Developer ID, notarization, and the app icon (T-005). Debug builds sign ad hoc ("Sign to Run Locally").
- Localization. English only (spec Assumptions).

## 3. Open Questions

- Bundle identifier: `com.muchfiner.HabitCal` for Release, `com.muchfiner.HabitCal.debug` for Debug, so dev and test runs never share the installed copy's container, defaults, or single-instance check. The Release ID is assumed from the About link's domain: easy to change before T-005, painful after the first release.
- Ad-hoc–signed login-item behavior can differ from a Developer ID build, so T-005 repeats the Launch at login manual tests on the signed build.

## 4. Requirements

### Spec Review

| Source | Direct claim | Changes it? |
| ------ | ------------ | ----------- |
| T-002 spec B.1–B.3 | The icon shows today's month and day; it updates within 1 minute of a date change; no Dock icon | No |
| T-002 spec B.4–B.5 | Each open shows the list and the current month; Esc is checked in order | No |
| T-002 spec B.6–B.10 | 6×7 grid in week-start order, today circled, paging with no limit | No |
| T-002 spec B.11–B.19 | Settings: week start (following the Mac, override rules), Launch at login, the link, Quit/⌘Q | No |
| T-002 spec E.1–E.10 | Rollover while open, single instance, login-item approval and failure, accessibility, appearance, Downloads copy | E.10 added by this design: the switch is disabled outside /Applications |
| ARCHITECTURE.md | App target + HabitCalKit; `Day`, `Clock` (named `TodaySource` here), `AppModel`; UserDefaults for settings | No; this design creates them |
| D-005 / D-007 | NSStatusItem + NSPopover; App Sandbox, no network entitlement | No |
| CONTRACTS.md | Doesn't exist; T-002 adds no contract beyond ⌘Q and the URL in its spec | No |

## 5. Current System Audit

Greenfield. A spike on 2026-10-29 (scratchpad, discarded) proved that Xcode 27.1 builds a hand-written `project.pbxproj` (objectVersion 77) with a `PBXFileSystemSynchronizedRootGroup` source folder, an `XCLocalSwiftPackageReference` to a local package, `GENERATE_INFOPLIST_FILE` with `INFOPLIST_KEY_LSUIElement = YES`, and `ENABLE_APP_SANDBOX = YES`. It needs `ALWAYS_SEARCH_USER_PATHS = NO` to avoid a warning. No project generator (XcodeGen, Tuist) is installed, and none is needed.

| Failure mode | Applicable / Not applicable / Checked—no issue / Accepted risk | Evidence |
| ------------ | -------------------------------------------------------------- | -------- |
| FM-001 Stale date after sleep or midnight | Applicable | `DayWatcher` observes four notifications plus a 60 s timer (§6) |
| FM-002 Instants instead of calendar days | Applicable | `Day` introduced; the only `Date`→`Day` conversion is in `DayWatcher` |
| FM-003 Saving destroys unreadable data | Not applicable | No data file until T-003 |
| FM-004 UI state off the main actor | Applicable | `AppModel` is `@MainActor`; observers use `queue: .main` and `MainActor.assumeIsolated` |
| FM-005 Ignoring Mac settings changes | Applicable | `Calendar.autoupdatingCurrent`, plus a `currentLocaleDidChange` observer |
| FM-006 Popover focus and dismissal | Applicable | `NSApp.activate()` before showing, `.transient`, UI test types Esc |
| FM-007 Tests depend on the real date | Applicable | `-HabitCalToday` launch argument; `FixedTodaySource` in unit tests |
| FM-008 UI tests can't reach the status item | Applicable; unproven | Slice 1 spike; fallback `-HabitCalOpenPopover` |
| FM-009 Login item from a translocated copy | Applicable | `LaunchAtLoginPolicy` refuses outside /Applications (E.9, E.10) |

## 6. Proposed Design

```
HabitCalKit (pure)                     HabitCal app (@MainActor)
  Day, Month                             AppDelegate ── StatusItemController ── MenuBarIcon
  MonthGrid.days(month, weekStart)          │                 │ click
  WeekStart (resolve / pick)                │           PopoverController (NSPopover .transient)
  LaunchAtLoginPolicy                       │                 │ NSHostingController
  MonthNames (English)                   DayWatcher ──▶ AppModel ◀── PopoverRoot (SwiftUI)
                                         LoginItem (SMAppService)   CalendarView, SettingsView
```

**HabitCalKit** (no AppKit or SwiftUI):
- `Day`: year, month, day; `Comparable`, `Hashable`, `Sendable`. `init(_ date: Date, calendar: Calendar)` is the one conversion. `weekday` uses the Gregorian calendar.
- `Month`: year and month, with `next`, `previous`, and `contains(Day)`.
- `MonthGrid.days(in: Month, weekStart: WeekStart) -> [Day]`: always 42 days.
- `WeekStart`: `.sunday` or `.monday`. `static func fromMac(firstWeekday: Int) -> WeekStart` maps 2 to `.monday` and everything else to `.sunday` (B.12). `static func resolve(override: WeekStart?, mac: WeekStart) -> WeekStart`. `static func overrideAfterPicking(_ picked: WeekStart, current: WeekStart?, mac: WeekStart) -> WeekStart?` returns nil only when there's no override and the pick equals the Mac's day (B.13).
- `LaunchAtLoginPolicy`: `shouldRegisterAtLaunch(inApplications:, initialized:) -> Bool`, true only when in /Applications and not yet initialized (B.17, E.9). `isInApplications(bundleURL:)` is true only for paths under `/Applications/`. `~/Applications` isn't supported: the sandbox hides the real home folder.
- `MonthNames`: English month names, abbreviations ("OCT"), and weekday initials, so the views and the icon share one source.
- `TodaySource` (named to avoid Swift's standard `Clock`): a protocol, `func today(in calendar: Calendar) -> Day`. `SystemTodaySource` reads `Date.now`; `FixedTodaySource(Day)` is for tests and `-HabitCalToday`. It's the only place `Date.now` appears (FM-007).

**App target:**
- `main.swift` creates `NSApplication` with `AppDelegate`. The Info.plist has `LSUIElement = YES` (B.3), so there's no Dock icon. A hidden main menu, built in `MainMenu.swift`, holds "Quit HabitCal" with ⌘Q, so the key works whenever the app is active, which it is while the popover is open (B.19). T-003 adds the Edit menu items (Cut, Copy, Paste, Select All, Undo) there, because without them the form's text fields don't get ⌘C, ⌘V, or ⌘A.
- `AppDelegate.applicationDidFinishLaunching`:
  1. Single-instance check: another `NSRunningApplication` with this bundle ID → `NSApp.terminate` (E.2).
  2. Build `LaunchOptions` from the arguments (Debug only).
  3. Create `AppModel`, `DayWatcher`, `StatusItemController`, and `PopoverController`.
  4. Apply the launch-at-login policy (B.17).
- `LaunchOptions` (`#if DEBUG`):
  - `-HabitCalToday YYYY-MM-DD` sets a fixed clock.
  - `-HabitCalMacFirstWeekday N` overrides the Mac's setting.
  - `-HabitCalDefaultsSuite name` makes UserDefaults use that suite.
  - `-HabitCalOpenPopover` is the FM-008 fallback.
  
  UI tests always pass the fixed-today and defaults-suite options (FM-007). Their app runs from DerivedData, so the launch-at-login policy already refuses to register.
- `AppModel` (`@MainActor @Observable`):
  - **State:** `today: Day`, `displayedMonth: Month`, `screen: Screen` (`.list` or `.settings`; T-003 adds `.form`), `weekStartOverride: WeekStart?` (persisted in UserDefaults key `weekStartOverride`), `macWeekStart: WeekStart`, and `loginItemState: LoginItemState`.
  - **Methods:** `resetForOpen()`, `showPreviousMonth()`, `showNextMonth()`, `showToday()`, `openSettings()`, `closeSettings()`, `pickWeekStart(_:)`, `useMacWeekStart()`, `refreshLoginItemState()`, `setLaunchAtLogin(_:)`, and `escape() -> EscapeResult` (`.handled` or `.closePopover`).
  - **Computed:** `weekStart` and `gridDays`.
- `DayWatcher` takes a `TodaySource` and the autoupdating calendar. It recomputes `Day` on:
  - `NSCalendarDayChanged`;
  - `NSWorkspace.didWakeNotification` (on the workspace center);
  - `NSSystemClockDidChange` and `NSSystemTimeZoneDidChange`;
  - a 60 s repeating `Timer` (B.2, FM-001).
  
  It also re-reads `firstWeekday` on `NSLocale.currentLocaleDidChangeNotification` and on the same timer (B.12, FM-005). It sets `model.today` and `model.macWeekStart` only when they change. When `today` changes, it calls `statusItemController.refresh()` directly; it's the only writer of `today`, so no observation tracking is needed.
- `StatusItemController` holds an `NSStatusItem` (variable length). Its button image comes from `MenuBarIcon.image(for: Day)`. `refresh()` redraws it from `model.today`. Its accessibility label is "HabitCal, Thursday, October 29" (B.1, E.6). A click toggles the popover.
- `MenuBarIcon` draws an 18 pt-tall template `NSImage` with a drawing handler:
  1. A rounded-rectangle stroke.
  2. The header bar, filled.
  3. The month abbreviation drawn with `.destinationOut`, so it's cut out of the bar. Steps 1–4 are wrapped in `beginTransparencyLayer` / `endTransparencyLayer`, so the cut-out can't erase the status button's highlight.
  4. The day number, bold.
  
  It's a template image, so macOS tints it for light, dark, and tinted menu bars and for Increase Contrast (E.7). The geometry follows the prototype's 21×21 viewBox, scaled.
- `PopoverController` holds an `NSPopover` with `.transient` behavior, which closes it on an outside click (B.5). Its content is a `PopoverHostingController`, a subclass of `NSHostingController<PopoverRoot>`.
  - **Opening:** `model.resetForOpen()`, which sets `screen = .list` and `displayedMonth = Month(today)` (B.4), then `NSApp.activate()` (FM-006), then `show(relativeTo:of:preferredEdge: .minY)`, then `makeFirstResponder(hostingController.view)`, so Esc enters the responder chain at the hosting view and not at the popover's window.
  - **Closing:** a second click on the icon closes it.
- **Esc:** `PopoverHostingController` overrides `cancelOperation(_:)` and calls `model.escape()`, closing the popover only on `.closePopover` (B.5). Esc reaches `cancelOperation` through the responder chain whether or not anything has focus. `.onKeyPress` and `.onExitCommand` were rejected: they need focus, and buttons don't take focus unless the Mac's Keyboard navigation setting is on. T-003 adds the right-click menu and form cases to `escape()`; T-003 must prove the Esc path from a text field, because the field editor (`NSTextView`) handles `cancelOperation` itself.
- `PopoverRoot` switches on `model.screen`.
- **Click to close:** a mouse-down outside a `.transient` popover closes it before the button's action runs. `popoverDidClose` (NSPopoverDelegate) records `ProcessInfo.processInfo.systemUptime`, not `Date.now`. The toggle checks `popover.isShown` and that time, and ignores a reopen within 0.3 s, so a click on the icon closes it and doesn't reopen it.
- `CalendarView`:
  - **Header:** "October 2026", then the ‹ / Today / › buttons with their spoken labels (E.6).
  - **Grid:** a `LazyVGrid` of 7 columns: the weekday initials row, then 42 day cells.
    - Neighboring-month days are drawn in `.tertiary`.
    - Today gets an accent circle (B.7).
    - Each cell's spoken label is the full date, plus ", today" for today.
- `SettingsView` follows the spec's UI section.
  - **Launch at login switch:** bound to `model.loginItemState`; refreshed `onAppear` (B.16, E.5). `LoginItemState` maps `SMAppService.Status` like this:
    - `.enabled` → on.
    - `.notRegistered` and `.notFound` → off; turning it on registers.
    - `.requiresApproval` → off, with the caption as a button that calls `SMAppService.openSystemSettingsLoginItems()` (E.3). This is also what a user who switched HabitCal off in System Settings sees (E.5), which is accurate, because that's where it has to be turned back on.
    - `.notInApplications`, from the policy → disabled, with the caption (E.10). `AppModel.refreshLoginItemState()` checks the policy first, so this wins over any `SMAppService` status: a Downloads copy can see `.enabled` from an earlier /Applications registration.
  - **The link:** `NSWorkspace.shared.open(url)`, then close (B.18).
  - **Quit:** `NSApp.terminate(nil)`.
- `LoginItem` wraps `SMAppService.mainApp`: `status`, `register()`, and `unregister()`. It maps the status to `LoginItemState`, and its errors map to a refresh of the real state (E.4).

| New state | Owner | Lifetime | Persist? | Why |
| --------- | ----- | -------- | -------- | --- |
| `today` | AppModel, set by DayWatcher | Process | No | Single source of "today" (FM-002, FM-007) |
| `displayedMonth`, `screen` | AppModel | Until the popover closes | No | B.4 resets them on each open |
| `weekStartOverride` | AppModel | Forever | UserDefaults `weekStartOverride` ("sunday"/"monday"; absent = follow the Mac) | B.15 |
| `macWeekStart` | AppModel, set by DayWatcher | Process | No | Always read from the Mac (B.12) |
| `launchAtLoginInitialized` | AppDelegate / AppModel | Forever | UserDefaults `launchAtLoginInitialized` | B.17: turn it on once; set true when it runs or when the user touches the switch |
| `loginItemState` | AppModel | Until the next refresh | No; macOS owns it | B.16 |

| Operation | Triggers | Caller | Boundary | Handler/event | Registration | Consumer/state | Restore/cleanup | Test | Evidence |
| --------- | -------- | ------ | -------- | ------------- | ------------ | -------------- | --------------- | ---- | -------- |
| Show date in icon | launch, `today` change | StatusItemController | AppKit status bar | `MenuBarIcon.image` | `applicationDidFinishLaunching` | button image + accessibility label | — | UI: `menuBarIconShowsTodaysDate`; manual icon look | B.1 |
| Day rollover | 4 notifications + timer | DayWatcher | NotificationCenter, NSWorkspace | `recompute()` | DayWatcher init | `model.today`, `statusItemController.refresh()` | Observers live as long as the app | Unit: `dayFromDateUsesTheGivenCalendarsTimeZone`; manual rollover (the wiring can't be automated: real OS events) | B.2, E.1 |
| Open / close popover | icon click, outside click, Esc | StatusItemController / NSPopover / PopoverHostingController | AppKit popover, responder chain | `toggle()`, `cancelOperation` → `model.escape()` | button action | `screen`, `displayedMonth` reset | `.transient` close | UI: `popoverOpensOnCurrentMonthAndListAndClosesOnSecondClick`, `escapeLeavesSettingsThenClosesPopover` | B.4, B.5 |
| Page months | ‹ / › / Today | CalendarView | — | AppModel methods | SwiftUI buttons | `displayedMonth` | reset on open | Unit: grid/month; UI: `pagingAcrossYearAndBackToToday` | B.6–B.10 |
| Week start | segmented control, link, Mac change | SettingsView, DayWatcher | UserDefaults, Calendar | `pickWeekStart`, `useMacWeekStart` | — | `weekStartOverride`, `macWeekStart` | — | Unit: `WeekStart` rules; UI: `overridingWeekStartReordersCalendarAndPersists` | B.12–B.15 |
| Launch at login | switch, first launch | SettingsView, AppDelegate | SMAppService | `LoginItem.register/unregister` | launch policy | `loginItemState` | refresh on Settings open | Unit: `LaunchAtLoginPolicy`; manual login-items checks | B.16, B.17, E.3–E.5, E.9, E.10 |
| Open website | link click | SettingsView | NSWorkspace | `open(url)` | — | popover closes | — | Manual (a UI test would open a real browser on every run) | B.18 |
| Quit | Quit button, ⌘Q | SettingsView, main menu | NSApplication | `terminate` | main menu built at launch | — | — | UI: `quitButtonAndCommandQQuit` | B.19 |
| Single instance | second launch | AppDelegate | NSRunningApplication | terminate self | launch | — | — | Manual: launch a second copy | E.2 |

| Guarantee | Mechanism | Owner | Linearization point | Failure behavior | Proof |
| --------- | --------- | ----- | ------------------- | ---------------- | ----- |
| The icon is at most 60 s stale | Notifications + 60 s timer | DayWatcher | assignment to `model.today` | A missed notification is caught by the timer | Manual rollover test |
| Each open starts on the list and the current month | `resetForOpen()` before `show` | PopoverController | the `resetForOpen` call | — | UI test |
| No login item from outside /Applications | Policy check before every `register()` | LaunchAtLoginPolicy | the check in `setLaunchAtLogin` and at launch | Switch disabled (E.10) | Unit + manual |

| Boundary | Concurrent event | Invariant | Linearization point | Recovery |
| -------- | ---------------- | --------- | ------------------- | -------- |
| Date change while the popover is open | user is paging | Displayed month unchanged; today's circle moves (E.1) | `model.today` set on main | — |
| `register()` throws while the switch animates | user toggles quickly | The switch shows the real status | `refreshLoginItemState()` after every call | E.4 |

### Red Flags Audit

| Red flag | Present? | If present, why acceptable |
| ---------------------- | -------- | -------------------------- |
| Shallow module | No | `AppModel` owns each operation end to end; views call one method |
| Information leakage | No | UserDefaults keys and the `SMAppService` status stay inside `AppModel` / `LoginItem` |
| Temporal decomposition | No | `Day` conversion has one home (`DayWatcher`) |
| Pass-through method | No | `LoginItem` maps `SMAppService.Status` to `LoginItemState` and turns errors into a refresh, so it has policy |

## 7. Interface Contract

| Interface | Inputs | Output | Errors | Async? |
| --------- | ------ | ------ | ------ | ------ |
| `MonthGrid.days(in:weekStart:)` | `Month`, `WeekStart` | `[Day]`, count 42 | — | No |
| `WeekStart.fromMac(firstWeekday:)` | Int 1–7 | `WeekStart` | — | No |
| `WeekStart.overrideAfterPicking(_:current:mac:)` | picked, current override, Mac's day | new override or nil | — | No |
| `LaunchAtLoginPolicy.shouldRegisterAtLaunch(inApplications:initialized:)` | Bool, Bool | Bool | — | No |
| `Day.init(_:calendar:)` | `Date`, `Calendar` | `Day` | — | No |
| `AppModel.escape()` | — | `.handled` or `.closePopover` | — | No, main actor |
| `LoginItem.register()/unregister()` | — | — | `SMAppService` errors → refresh | No, main actor |

Notifications, all delivered on the main queue to DayWatcher: `NSCalendarDayChanged`, `NSSystemClockDidChange`, `NSSystemTimeZoneDidChange`, and `NSLocale.currentLocaleDidChangeNotification` come from the default center; `NSWorkspace.didWakeNotification` comes from `NSWorkspace.shared.notificationCenter`. HabitCalKit types are `Sendable` values; `AppModel` and the controllers are `@MainActor`.

## 8. Data Model & Persistence

Two UserDefaults keys in the app's sandboxed domain:
- `weekStartOverride`: string, "sunday" or "monday"; absent means follow the Mac.
- `launchAtLoginInitialized`: Bool.

An unknown value reads as absent. No habit data yet; T-003 adds `habits.json`. UI tests use `-HabitCalDefaultsSuite` with a fresh suite name per test. The leftover suite files in the Debug app's container are accepted: the test runner can't reach them to clean up.

## 9. Capabilities & Security

- **Sandbox:** `ENABLE_APP_SANDBOX = YES`, with no other entitlements: no network, no file access beyond the container (D-007). `NSWorkspace.open(https URL)` works from the sandbox.
- **Hardened runtime:** on for Release, with no exceptions.
- **Launch at login:** `SMAppService.mainApp` needs no entitlement. The user may need to approve it in System Settings (E.3).
- **Input from disk:** UserDefaults values are validated (unknown → absent). Launch options are compiled only in Debug.

## 10. macOS Versions and Appearance

| Variant | Difference from baseline | Verified how |
| ------- | ------------------------ | ------------ |
| macOS 16+ | None expected; the status item and popover APIs are unchanged | Run on the dev Mac (macOS 27) |
| Intel | None; universal build | Build setting `ARCHS = $(ARCHS_STANDARD)` |
| Dark mode, tinted menu bar | The icon is a template image, tinted by macOS; the popover uses system colors | Manual: menu bar icon |
| Increase Contrast | Template icon and system colors adapt | Manual: menu bar icon |
| VoiceOver | Labels from E.6 | UI tests query by label; manual VoiceOver pass |

## 11. Alternatives / Reuse / Proportionality

| Checked | Stdlib / native / existing dep / new dep | Covers? | Why not | Ceiling / upgrade path |
| ------- | ---------------------------------------- | ------- | ------- | ---------------------- |
| SwiftUI `MenuBarExtra` | native | Partly | Can't close itself or detect opening (D-005) | — |
| XcodeGen / Tuist to generate the project | new dev tool | Yes | Adds a tool every contributor needs; the spike shows a hand-written synchronized project is small and stable | Adopt one if the project file grows painful |
| `NSCalendarDayChanged` alone for rollover | native | No | Unreliable after sleep (FM-001) | — |
| Rendering the icon with SwiftUI `ImageRenderer` | native | Yes | The `.destinationOut` cut-out is simpler in an `NSImage` drawing handler, and no SwiftUI view is needed in the status bar | — |
| A login-item helper app | native | Yes | `SMAppService.mainApp` does it with no helper | — |

| Rare case | Cost to support | Requirement change that deletes it | Recommend |
| --------- | --------------- | ---------------------------------- | --------- |
| Mac's first weekday other than Sun/Mon | One mapping line | — | Keep (B.12) |
| Running from Downloads | Policy + disabled switch | — | Keep; it's the common first launch for a GitHub download |

## 12. Implementation Slicing Strategy

Four slices; st-slice writes the plan.
1. **Skeleton and FM-008 spike:** the project (Debug bundle ID `.debug`), HabitCalKit with `Day` and `TodaySource`, an app with a status item (plain icon) and an empty popover, and a UI test that clicks the status item, finds the popover, and clicks again to close it. Also confirm that repeated ad-hoc rebuilds relaunch sandboxed without a container-access prompt. If clicking fails, switch to `-HabitCalOpenPopover`, record FM-008 as seen, and move to manual the UI tests that need a second open: `reopeningPopoverResetsToCurrentMonth` and the click-to-close step.
2. **Icon and rollover:** `MenuBarIcon`, `DayWatcher`, and the launch options for a fixed today.
3. **Calendar:** `Month`, `MonthGrid`, `WeekStart` resolution from the Mac, `CalendarView`, paging, reset on open, and Esc.
4. **Settings:** About and the link, the week-start override, Launch at login with its policy, Quit and ⌘Q, single instance, and the hidden main menu.

## 13. Testing Strategy

Unit tests (Swift Testing, HabitCalKit):

| Test | Kind | Spec rules proved | Regression prevented |
| ---- | ---- | ----------------- | -------------------- |
| `gridAlwaysHasSixWeeksStartingOnWeekStart` | unit | B.6, Limits | Grid height jumping |
| `gridIncludesNeighbouringMonthDays` | unit | B.6, B.7 | Missing faint days |
| `nextAndPreviousMonthCrossYearBoundaries` | unit | B.8, B.10 | December → January bugs |
| `macFirstWeekdayMapsMondayToMondayAndOthersToSunday` | unit | B.12 | Wrong mapping |
| `pickingMacDayWithoutOverrideKeepsFollowingMac` / `pickingWhileOverriddenKeepsOverride` / `pickingOtherDayOverrides` | unit | B.13 | Override rules |
| `launchAtLoginRegistersOnlyFirstLaunchFromApplications` | unit | B.17, E.9 | Login item from Downloads |
| `onlyTheApplicationsFolderCountsAsInstalled` | unit | E.9, E.10 | Path check |
| `dayFromDateUsesTheGivenCalendarsTimeZone` | unit | B.1, B.2 | Off-by-one days (FM-002) |

UI tests (XCUITest, launched with a fixed today 2026-10-29 and a fresh defaults suite):

| Test | Kind | Spec rules proved | Regression prevented |
| ---- | ---- | ----------------- | -------------------- |
| `menuBarIconShowsTodaysDate` | UI | B.1, E.6 (icon label) | Wrong date |
| `popoverOpensOnCurrentMonthAndListAndClosesOnSecondClick` | UI | B.4, B.5, B.6, B.7 | Stale month; transient close-then-reopen |
| `pagingAcrossYearAndBackToToday` | UI | B.8–B.10 | Navigation |
| `reopeningPopoverResetsToCurrentMonth` | UI | B.4 | State kept across opens |
| `escapeLeavesSettingsThenClosesPopover` (nothing focused) | UI | B.5, B.11 | Esc order, focus (FM-006) |
| `settingsBackKeepsDisplayedMonth` | UI | B.11 | — |
| `overridingWeekStartReordersCalendarAndPersists` (relaunch with the same suite) | UI | B.13–B.15 | Override lost |
| `macWeekStartIsUsedUntilOverridden` (`-HabitCalMacFirstWeekday 2`) | UI | B.12, B.14 | — |
| `quitButtonAndCommandQQuit` | UI | B.19 | ⌘Q missing without a menu |
| `controlsHaveSpokenLabels` | UI | E.6 | — |

Manual tests (`docs/manual-tests/menu-bar.md`), each because automation can't reach it:

| Test | Kind | Spec rules proved | Why manual |
| ---- | ---- | ----------------- | ---------- |
| Icon at actual size: light, dark, tinted, Increase Contrast | manual | E.7, B.1 | Visual |
| Rollover: midnight, sleep through midnight, clock and time zone change, while open | manual | B.2, E.1 | Real time and OS events |
| No Dock icon or app-switcher entry | manual | B.3 | OS chrome |
| Launch at login: first launch from /Applications, off and on, logout/login, approval, removed in System Settings, running from Downloads | manual | B.16, B.17, E.3–E.5, E.9, E.10 | Real login items must not be registered by tests |
| Change the Mac's first weekday while running | manual | B.12 | System Settings |
| Second copy exits | manual | E.2 | Two app instances |
| The link opens the browser | manual | B.18 | Browser |
| VoiceOver pass, and Tab through every control with Keyboard navigation on | manual | E.6 | Speech; Tab reaches buttons only with that Mac setting on |
| Crowded menu bar | — | E.8 | Accepted; nothing to test |

## 14. Rollout

Direct ship, no flag. This task first creates the app; signing for distribution is T-005.

## 15. Reviewer Feedback

| \#  | Finding | Severity | Cost to accept | Decision | Rationale | Next step | Arch? | Source |
| --- | ------- | -------- | -------------- | -------- | --------- | --------- | ----- | ------ |
| 1 | `.onKeyPress(.escape)` needs focus; NSPopover closes on Esc otherwise | MAJOR | Small | ACCEPT | B.5 fails in the common state | `cancelOperation` override in `PopoverHostingController` | Yes | Pass 1 |
| 2 | Debug and Release share a bundle ID: single-instance kills tests; shared container | MAJOR | One setting | ACCEPT | Breaks Goal 2 on the dogfooding Mac | `.debug` suffix for Debug | Yes | Pass 1 |
| 3 | Phantom rollover test; `withObservationTracking` fires before the change | MINOR | Small | ACCEPT | Stale icon risk | DayWatcher calls `refresh()` directly; wiring is manual | No | Pass 1 |
| 4 | `~/Applications` can't be seen from the sandbox | MINOR | Saves work | ACCEPT | Narrowed to `/Applications` | Spec E.9/E.10 wording | Yes (spec) | Pass 1 |
| 5 | `.destinationOut` can punch through the button highlight | MINOR | Two lines | ACCEPT | Visible glitch | Transparency layer | No | Pass 1 |
| 6 | Click-again-to-close untested; transient reopen bug | MINOR | Small | ACCEPT | Known NSPopover trap | Debounce + test step | No | Pass 1 |
| 7 | Link test opens a real browser; no-login-item option does nothing; suite teardown impossible | MINOR | Saves work | ACCEPT | Flaky and dead seams | B.18 manual; option dropped; leftovers accepted | No | Pass 1 |
| 8 | `Clock` undefined, and it collides with Swift's `Clock` | MINOR | Small | ACCEPT | Interface gap | `TodaySource` defined in §6 | Yes | Pass 1 |
| 9 | Lasting Changes leaves out the main menu, Esc extension point, contracts, Debug ID | MINOR | Small | ACCEPT | T-003 needs them | Rows added to §16 | Yes | Pass 1 |
| 11 | Esc may start at the popover window, not the hosting view | MINOR | One line | ACCEPT | Mechanism stated as settled | `makeFirstResponder` after `show`; the UI test proves it | No | Pass 2 |
| 12 | Text fields don't forward Esc as `cancelOperation` | MINOR | Saves a false claim | ACCEPT | `NSTextView` handles it | T-003 proves the path | No | Pass 2 |
| 13 | Debounce: where the close time is recorded, which clock, Esc-then-click flakiness | MINOR | Small | ACCEPT | Unspecified mechanism | `popoverDidClose` + `systemUptime`; reopening tests wait past 0.3 s | No | Pass 2 |
| 14 | Policy vs. `SMAppService` status precedence | MINOR | One line | ACCEPT | E.10 could fail | Policy checked first | No | Pass 2 |
| 15 | CONVENTIONS.md still says `Clock` | MINOR | One row | ACCEPT | Lasting docs drift | §16 row extended | Yes | Pass 2 |
| 10 | `LoginItemState` mapping for `.notFound` and System-Settings-off; signed-build retest | QUESTION | Small | ACCEPT | Answered in §6; retest goes to T-005 | Mapping written; T-005 note | No | Pass 1 |

## 16. Lasting Changes

| Change | Goes to |
| ------ | ------- |
| Real file layout and component list, and the CONVENTIONS.md Dates rule's `Clock` renamed to `TodaySource` (AppDelegate, MainMenu, StatusItemController, PopoverController, PopoverHostingController, DayWatcher, MenuBarIcon, LoginItem, AppModel; HabitCalKit Day, Month, MonthGrid, WeekStart, TodaySource, LaunchAtLoginPolicy, MonthNames) | ARCHITECTURE.md, CONVENTIONS.md |
| The popover's extension points: `Screen` and `AppModel.escape()`; Esc arrives through `cancelOperation` in `PopoverHostingController`; the hidden main menu gets the Edit items when T-003 adds text fields | ARCHITECTURE.md, and CONVENTIONS.md: "handle Esc in `escape()`, never with `.onKeyPress`" |
| Rejected for Esc: `.onKeyPress` and `.onExitCommand`, which need focus | CONVENTIONS.md rule above; COMMON-FAILURE-MODES.md FM-006 example |
| Debug bundle ID `com.muchfiner.HabitCal.debug` and why | ARCHITECTURE.md |
| Spec contracts: ⌘Q quits, the About link URL | CONTRACTS.md (created at close) |
| UserDefaults keys `weekStartOverride`, `launchAtLoginInitialized` | ARCHITECTURE.md, State and Persistence |
| Debug launch options, and that UI tests always pass the fixed-today and defaults-suite options | TESTING.md |
| Confirmed commands, and the FM-008 outcome | TESTING.md, COMMON-FAILURE-MODES.md |
| The project file is hand-written with synchronized folders; add files by putting them in the folder | CONVENTIONS.md, Structure |
| Rejected: XcodeGen/Tuist | ARCHITECTURE.md's stack note |
| Release bundle ID `com.muchfiner.HabitCal` | ARCHITECTURE.md |
| Manual tests for the menu bar area | docs/manual-tests/menu-bar.md |
