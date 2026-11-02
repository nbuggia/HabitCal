# Testing

Commands confirmed with Xcode 27.1 on 2026-10-29.

## Kinds of test

| Kind | Tool | Lives in | Proves |
| --- | --- | --- | --- |
| Unit | Swift Testing (`@Test`, `#expect`) | `HabitCalKit/Tests/HabitCalKitTests/` | Rules with many cases: due days, schedule changes, streaks, schedule labels, week-start mapping |
| Integration | Swift Testing | `HabitCalKit/Tests/HabitCalKitTests/` | `HabitStore` against a real temporary directory: save, reload, atomic replace, older formats, unreadable and newer-format files |
| UI | XCTest UI testing (`XCUIApplication`) | `HabitCalUITests/` | Each spec's use cases through the running app: popover, calendar paging, form, check-offs, Settings |
| Manual | `docs/manual-tests/<area>.md` | | What automation can't reach (below) |

UI tests launch the app with Debug-only launch arguments, so they never depend on the real date or touch real settings (FM-007):

- `-HabitCalToday YYYY-MM-DD`: a fixed today. Always passed.
- `-HabitCalDefaultsSuite name`: a fresh UserDefaults suite. Always passed (a new UUID per launch; reuse one to test persistence across a relaunch). Leftover suites in the Debug container are accepted.
- `-HabitCalMacFirstWeekday N`: pretend the Mac's first weekday is N (1 = Sunday).
- `-HabitCalDataDir name`: keep habits.json in Application Support/HabitCal-tests/<name> inside the app's container. Always passed (a new name per launch; reuse one to test persistence). It's a folder name, not a path: the sandboxed app can't reach the test runner's folders, and the runner can't read the app's.
- `-HabitCalSeedData base64`: the exact bytes to write to habits.json before loading, to start from known habits or an unreadable file.

`HabitCalUITestCase` passes all of these and holds the shared lookups (`element`, `text`, `openPopover`).

The UI-test app runs from DerivedData, never /Applications, so it never registers a login item.

The UI tests assume the Mac's Keyboard navigation setting is off: with it on, every button (the 42 calendar days included, T-022) becomes a Tab stop, which changes where focus lands.

XCUITest on macOS: a SwiftUI `Text`'s string is its accessibility **value**, not its label; link-style buttons are links, not buttons, so find them by label; text inside a button merges into the button's label (find habit rows by "Edit <name>", whose value is the schedule label); keyboard focus isn't exposed for SwiftUI focusable views, so prove focus by behavior (Tab, then a key that changes something). To look at a screen, attach `popover.screenshot()` as an `XCTAttachment` (keepAlways), run with `-resultBundlePath`, and `xcrun xcresulttool export attachments`. Mark test classes `@MainActor` with async `setUp`/`tearDown` under Swift 6. A test that reopens the popover right after closing it waits 0.5 s first (the reopen guard).

## Commands

`./run.py` wraps these (standard library only, the macOS Python 3.9): `run`, `build`, `open`, `stop`, `test`, `uitest [Suite[/test]]`, `lint`, `format`, `clean`. `./run.py --help` lists them.

```sh
# Unit and integration tests (fast; run on every change to HabitCalKit)
swift test --package-path HabitCalKit

# Build the app and run the UI tests (~3–4 minutes; they drive the real screen)
xcodebuild test -project HabitCal.xcodeproj -scheme HabitCal -destination 'platform=macOS' -derivedDataPath build/dd

# Format check (swift-format ships with the toolchain)
swift format lint --recursive --strict HabitCal HabitCalKit HabitCalUITests   # config: .swift-format
# Fix formatting in place
swift format --in-place --recursive HabitCal HabitCalKit HabitCalUITests
```

## Validation order

1. Format check on the changed files.
2. `swift test --package-path HabitCalKit` for any change to HabitCalKit.
3. The UI tests for the product area the change touches (`-only-testing:HabitCalUITests/<Suite>`).
4. Before a task's close: the full `xcodebuild test`, plus that area's manual tests.

## Naming

A test's name states the behavior it proves, in users' terms: `streakSkipsDaysTheHabitIsNotDue`, not `testStreak2`. Suites are grouped by product area: Menu bar, Calendar, Settings, Habits, Streaks, Saving. Tests are where the product's behavior lasts once a task closes.

## What automation can't reach

These live in `docs/manual-tests/<area>.md` (`menu-bar.md`, `habits.md`):

- **Menu bar icon:** how it looks at actual size in light, dark, and tinted menu bars, and with Increase Contrast.
- **Day rollover:** across real midnight, sleep through midnight, and manual clock and time zone changes.
- **Launch at login:** a real logout and login, approval in System Settings › Login Items, and running from Downloads versus /Applications.
- **VoiceOver:** spoken labels, the order things are read in, and that it skips the strip (T-041).
- **Habits:** colors in every appearance, scrolling with many habits, a failed save (read-only folder), copy and paste.
- **Distribution:** a notarized build opening cleanly from a GitHub download.
