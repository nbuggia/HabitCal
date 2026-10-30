# Contracts

The promises HabitCal makes to users and other systems, which must hold across every change. ARCHITECTURE.md names the component that implements each; DECISIONS.md holds why.

## ⌘Q quits

- **Promise:** while the popover is open, ⌘Q quits HabitCal.
- **Relied on by:** users' muscle memory; a Dock-less app has no other standard way to quit.
- **Versioning:** never removed.
- **Tested by:** `testCommandQQuitsWhilePopoverIsOpen`.

## About link

- **Promise:** the link in Settings opens https://www.muchfiner.com in the default browser.
- **Relied on by:** users looking for the app's home page.
- **Versioning:** change the URL only with a redirect from the old one.
- **Tested by:** manual test "The website link opens the browser" (`docs/manual-tests/menu-bar.md`).

## Saved habit data (habits.json, format version 1)

- **Promise:** habits are saved in `Application Support/HabitCal/habits.json` in the app's container, as UTF-8 JSON with sorted keys:
  ```json
  { "formatVersion": 1,
    "habits": [ { "id": "UUID", "name": "Run", "note": "", "addedOn": "2026-10-01",
                  "schedule": [ { "from": "2026-10-01", "days": ["sun", "fri"] } ],
                  "checkOffs": ["2026-10-02", "2026-10-04"] } ] }
  ```
  Habits are in list order. Dates are local calendar days ("YYYY-MM-DD"). Schedule entries are sorted by `from`; `days` are 1–7 distinct weekdays, "sun" through "sat", in that order; `checkOffs` are distinct and oldest first. A version-1 file has exactly these fields.
- **Relied on by:** every later version of HabitCal, which must read every earlier format; users' history; a future export.
- **Versioning:** any change to what is written bumps `formatVersion`. A version that finds a format it doesn't know, or fields and values its version never writes, treats the file as unreadable, shows the E.5 message, and never writes over it, so a downgrade can't destroy history (D-004).
- **Tested by:** `version1FixtureLoads` (fixture `HabitCalKit/Tests/HabitCalKitTests/Fixtures/habits-v1.json`), `savedHabitsLoadBackUnchanged`, `savedFileIsSortedAndReadable`, `newerFormatIsNeverOverwritten`, `unknownFieldsInAVersion1FileMakeItUnreadable`, `unreadableFileIsNeverOverwritten`, `saveBeforeLoadIsRefused`.
