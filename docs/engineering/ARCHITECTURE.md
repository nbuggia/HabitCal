# Architecture

Describes what is built. T-002 built the shell (menu bar, popover, calendar, Settings). Habits (T-003) and streaks (T-004) are described where they're planned, and their closes update this.

## Stack

- Swift 6 language mode with strict concurrency, built with Xcode 27.1 (Swift 6.4).
- SwiftUI for every screen; AppKit for the menu bar item, the popover, and app lifecycle.
- macOS 15 (Sequoia) or later, universal binary (Apple silicon and Intel).
- No third-party dependencies (PRD Constraints).
- Distribution: Developer ID–signed, notarized, hardened runtime, App Sandbox, downloaded from GitHub (PRD Constraints, D-007).
- Bundle IDs: `com.muchfiner.HabitCal` (Release) and `com.muchfiner.HabitCal.debug` (Debug), so dev and test runs never share the installed copy's container, UserDefaults, or single-instance check.
- The project file is hand-written (`objectVersion 77`) with folder-synced groups: every file in `HabitCal/` and `HabitCalUITests/` is in its target automatically. XcodeGen and Tuist were considered and not needed.

| Dependency | What it does for us | Why this one |
| --- | --- | --- |
| AppKit `NSStatusItem` + `NSPopover` | The menu bar icon and the popover it opens | D-005 |
| SwiftUI | All popover content, hosted in `NSHostingController` | Native; the prototype's layout maps to it directly |
| ServiceManagement `SMAppService.mainApp` | Launch at login | The supported API on macOS 13+; no helper app |
| Foundation `JSONEncoder` / `JSONDecoder` | Saving habit data | D-006 |
| Swift Testing | Unit and integration tests in HabitCalKit | Ships with the toolchain |
| XCTest UI testing (`XCUIApplication`) | UI tests of the running app | The only UI automation for macOS apps |

## Components

```
HabitCal.xcodeproj       hand-written; shared scheme "HabitCal"
HabitCal/                app target (LSUIElement: no Dock icon)
  main.swift             starts NSApplication with AppDelegate
  App/
    AppDelegate          single-instance check (later launch exits), MainMenu, wiring, first-launch login default
    MainMenu             hidden main menu: ⌘Q (T-003 adds the Edit menu)
    LaunchOptions        Debug-only test seams (see TESTING.md)
    StatusItemController the menu bar item: icon, spoken label, click
    PopoverController    NSPopover (.transient), open/close, 0.3 s reopen guard, first responder
    PopoverHostingController  hosts PopoverRoot; Esc arrives as cancelOperation → AppModel.escape()
    DayWatcher           only writer of today and macWeekStart: 4 notifications + 60 s timer + locale change
    LoginItem            SMAppService wrapper; /Applications policy wins over its status
  MenuBar/MenuBarIcon    tear-off calendar page as a template NSImage (D-008)
  Views/                 PopoverRoot, HabitListScreen, CalendarView, SettingsScreen, PhosphorIcon
  AppModel.swift         @MainActor @Observable: today, displayed month, Screen, week-start override, login state
  Assets.xcassets        Phosphor icons as template SVGs (THIRD-PARTY-NOTICES.md)
HabitCalUITests/         XCUITest journeys (MenuBarUITests)
HabitCalKit/             local Swift package; no AppKit or SwiftUI
  Sources/HabitCalKit/
    Day                  a local calendar date, never a Date instant; weekday, adding(days:)
    TodaySource          the only source of "today" (System / Fixed)
    Month, MonthGrid     displayed month; always 42 grid days
    WeekStart            Mac mapping, resolve, override-after-picking, orderedWeekdays
    MonthNames           English names and spoken labels
    LaunchAtLoginPolicy  /Applications check; first-launch default
    (T-003: Habit, Habits, HabitStore, ScheduleLabel; T-004: Streaks)
  Tests/HabitCalKitTests/
```

- **App (HabitCal target):** everything that touches macOS: the menu bar, the popover, windows and focus, launch at login, opening URLs, notifications about the day, clock, time zone, wake, and locale changes. It holds no habit rules; it asks HabitCalKit.
- **HabitCalKit:** every rule the specs state about habits, schedules, due days, streaks, week start, and saving. It is pure Swift plus Foundation, so `swift test` runs it in seconds with no app.

## Boundaries

- **App ↔ HabitCalKit:** a Swift module boundary. The app passes `Day` values and gets back values; HabitCalKit never sees a `Date`, an `NSView`, or a SwiftUI type.
- **App ↔ macOS:** status item and popover, `SMAppService`, `NSWorkspace` (open URL, wake notification), `NSCalendarDayChanged`, `NSSystemClockDidChange`, `NSSystemTimeZoneDidChange`, `NSLocale.currentLocaleDidChangeNotification`, `NSRunningApplication` (single instance).
- **HabitCalKit ↔ disk:** one JSON file, written atomically. The App Sandbox confines it to the app's container, and the absence of a network entitlement means the process can't open outgoing connections (D-007).

## State and Persistence

| State | Owner | Lifetime | Stored |
| --- | --- | --- | --- |
| Habits, schedule histories, check-offs | `HabitStore` (HabitCalKit), held by `AppModel` | Forever, until a habit is deleted | `~/Library/Containers/<bundle id>/Data/Library/Application Support/HabitCal/habits.json` |
| Week-start override, "launch at login initialized" flag | `AppModel` | Forever | `UserDefaults` keys `weekStartOverride` ("sunday"/"monday", absent = follow the Mac) and `launchAtLoginInitialized` (set once a first-launch registration succeeds, or when the user touches the switch) |
| Launch at login | macOS (`SMAppService`) | Forever | Read from macOS each time Settings opens; never cached |
| Displayed month, current screen, open form | `AppModel` | Until the popover closes | Memory only |

- `habits.json` carries `formatVersion`. HabitCalKit decodes every earlier version and migrates in memory; it writes only the current version. A file it can't decode, or one with a newer `formatVersion`, puts the store in a read-only "unreadable" state, and nothing is written (D-004).
- Dates in the file are local calendar days (`"2026-10-29"`), not timestamps, so a check-off never moves when the time zone changes.
- Saves are synchronous and atomic (write to a temporary file, then replace), on the main actor, after every change. The file is small: years of daily check-offs for a dozen habits stay well under 1 MB.

## The Popover

- `AppModel.screen` (`Screen`) picks the screen; `PopoverRoot` switches on it. Every open calls `resetForOpen()`: back to the list and the current month.
- Esc: `AppModel.escape()` backs out one level and returns `.closePopover` from the list. It's reached through `PopoverHostingController.cancelOperation`, and the hosting view is made first responder after each open and screen change, so it works whether or not a control has focus.
- The status item's click toggles the popover; `.transient` closes it on an outside click. A reopen within 0.3 s of closing is ignored, because the click that closes a transient popover would otherwise reopen it.

## External Interfaces

| Contract | Implemented by |
| --- | --- |
| ⌘Q quits | `MainMenu` |
| About link URL | `SettingsScreen` |
| Saved habit data (T-003 spec; CONTRACTS.md at T-003's close) | `HabitStore` in HabitCalKit |

## Open Questions

- Developer ID team and notarization credentials aren't set up yet. They're needed before the first release, not before T-002.
