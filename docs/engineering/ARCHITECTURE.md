# Architecture

No code exists yet. This describes the shape v1 is built to, starting with T-002, which creates the project. Each task's close updates this file to describe what was actually built.

## Stack

- Swift 6 language mode with strict concurrency, built with Xcode 27.1 (Swift 6.4).
- SwiftUI for every screen; AppKit for the menu bar item, the popover, and app lifecycle.
- macOS 15 (Sequoia) or later, universal binary (Apple silicon and Intel).
- No third-party dependencies (PRD Constraints).
- Distribution: Developer ID–signed, notarized, hardened runtime, App Sandbox, downloaded from GitHub (PRD Constraints, D-007).

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
HabitCal.xcodeproj
  HabitCal/            app target (LSUIElement: no Dock icon)
    App/               AppDelegate: status item, popover, single-instance check, day-change observers
    MenuBar/           icon rendering (tear-off calendar page as a template NSImage)
    Views/             SwiftUI screens: HabitList, CalendarGrid, HabitRow, HabitForm, Settings
    AppModel.swift     @MainActor @Observable: owns the displayed month, current screen, HabitStore, settings
  HabitCalUITests/     XCUITest journeys, one file per product area
HabitCalKit/           local Swift package, imported by the app; no AppKit or SwiftUI
  Sources/HabitCalKit/
    Day.swift          a local calendar date (year, month, day), never a Date instant
    Clock.swift        source of "today"; injectable for tests
    Habit.swift        habit, schedule history, check-offs; due-day rules
    Streaks.swift      current and best streak
    ScheduleLabel.swift
    WeekStart.swift    Mac setting → Sunday/Monday mapping, override
    HabitStore.swift   load/save of the data file, versioning, unreadable-data guard
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
| Week-start override, "launch at login initialized" flag | `AppModel` | Forever | `UserDefaults` |
| Launch at login | macOS (`SMAppService`) | Forever | Read from macOS each time Settings opens; never cached |
| Displayed month, current screen, open form | `AppModel` | Until the popover closes | Memory only |

- `habits.json` carries `formatVersion`. HabitCalKit decodes every earlier version and migrates in memory; it writes only the current version. A file it can't decode, or one with a newer `formatVersion`, puts the store in a read-only "unreadable" state, and nothing is written (D-004).
- Dates in the file are local calendar days (`"2026-10-29"`), not timestamps, so a check-off never moves when the time zone changes.
- Saves are synchronous and atomic (write to a temporary file, then replace), on the main actor, after every change. The file is small: years of daily check-offs for a dozen habits stay well under 1 MB.

## External Interfaces

| Contract | Implemented by |
| --- | --- |
| Saved habit data (T-003 spec; CONTRACTS.md at T-003's close) | `HabitStore` in HabitCalKit |

## Open Questions

- Developer ID team and notarization credentials aren't set up yet. They're needed before the first release, not before T-002.
- Whether `XCUIApplication` can open the popover through `statusItems` on macOS 15+ reliably enough for UI tests. T-002's design should prove it before relying on it (FM-008).
