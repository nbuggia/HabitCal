# Testing

No project exists yet, so the commands below are unconfirmed. T-002 creates the project and confirms them; update this file then.

## Kinds of test

| Kind | Tool | Lives in | Proves |
| --- | --- | --- | --- |
| Unit | Swift Testing (`@Test`, `#expect`) | `HabitCalKit/Tests/HabitCalKitTests/` | Rules with many cases: due days, schedule changes, streaks, schedule labels, week-start mapping |
| Integration | Swift Testing | `HabitCalKit/Tests/HabitCalKitTests/` | `HabitStore` against a real temporary directory: save, reload, atomic replace, older formats, unreadable and newer-format files |
| UI | XCTest UI testing (`XCUIApplication`) | `HabitCalUITests/` | Each spec's use cases through the running app: popover, calendar paging, form, check-offs, Settings |
| Manual | `docs/manual-tests/<area>.md` | | What automation can't reach (below) |

UI tests launch the app with launch arguments that set a fixed "today" and a temporary data directory, so they never depend on the real date or touch real data (FM-007).

## Commands

```sh
# Unit and integration tests (fast; run on every change to HabitCalKit)
swift test --package-path HabitCalKit

# Build the app and run the UI tests
xcodebuild test -project HabitCal.xcodeproj -scheme HabitCal -destination 'platform=macOS'

# Format check (swift-format ships with the toolchain)
swift format lint --recursive --strict HabitCal HabitCalKit HabitCalUITests
```

## Validation order

1. Format check on the changed files.
2. `swift test --package-path HabitCalKit` for any change to HabitCalKit.
3. The UI tests for the product area the change touches (`-only-testing:HabitCalUITests/<Suite>`).
4. Before a task's close: the full `xcodebuild test`, plus that area's manual tests.

## Naming

A test's name states the behavior it proves, in users' terms: `streakSkipsDaysTheHabitIsNotDue`, not `testStreak2`. Suites are grouped by product area: Menu bar, Calendar, Settings, Habits, Streaks, Saving. Tests are where the product's behavior lasts once a task closes.

## What automation can't reach

These live in `docs/manual-tests/<area>.md`, created when the first check is needed:

- **Menu bar icon:** how it looks at actual size in light, dark, and tinted menu bars, and with Increase Contrast.
- **Day rollover:** across real midnight, sleep through midnight, and manual clock and time zone changes.
- **Launch at login:** a real logout and login, approval in System Settings › Login Items, and running from Downloads versus /Applications.
- **VoiceOver:** spoken labels and the order things are read in.
- **Distribution:** a notarized build opening cleanly from a GitHub download.
