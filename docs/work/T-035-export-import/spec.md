---
name: Export and import habit data
task: T-035
status: Approved
last updated: 2026-10-31
---

# Spec: Export and Import Habit Data

## 1. Summary

Settings gets two buttons: one saves your habits to a file you choose, the other replaces your habits with the ones in such a file, after a confirmation. It's for people taking their habit history to a new Mac, or keeping a copy of it. Their history is the product's value (D-004), and it shouldn't be locked inside the app.

## 2. Users

- **For:** someone moving to a new Mac or reinstalling, and someone who wants a copy of their history they control.
- **Core value:** export on one Mac, import on another, and every habit, schedule, and check-off is the same. Imported the same day, every streak matches too; days after the export show as missed, and can be fixed from the strip.
- **Not for:** people wanting live sync between Macs (PRD Not Doing), or moving data in from other habit apps.

## 3. Not Doing

- Merging an imported file with the current habits. The customer chose replace (2026-10-31): moving to a new Mac is a replace, and merging needs rules for matching habits, names, and schedules.
- A backup or undo of the habits an import replaced. The customer chose a confirmation only (2026-10-31).
- Exporting settings (week start, launch at login). The history is what has value; settings take seconds to set again.
- Any format but HabitCal's own. A spreadsheet format can't carry schedule history, so it couldn't be imported back.
- Sync, or anything sent off the Mac (PRD Not Doing; D-004, D-007).

## 4. Current Behavior

- Habits are saved in one file inside the app's sandbox container, in a versioned JSON format, and nowhere else. There is no way to get a copy out or bring one in — CONTRACTS.md, "Saved habit data"; D-004, D-006.
- HabitCal can only reach files in its own container; it has no network access — D-007.
- When the saved file can't be read, including a newer format, HabitCal shows "HabitCal couldn't read your habits" with the file's path in place of the list, disables Add and the leaderboard, and never writes over the file — T-003 E.5; tests `newerFormatIsNeverOverwritten`, `unreadableFileIsNeverOverwritten`.
- When a save fails, "Couldn't save — your last change may be lost" shows above the list until a later save succeeds — T-003 E.6; manual test habits.md, "A failed save".
- Settings shows About (icon, name and version, website link), General (Launch at login, Week starts on), and Quit HabitCal — `SettingsScreen`; T-033.

## 5. UI

- A new section in Settings between General and Quit, headed **DATA** like GENERAL, in the same rounded group: two rows, **Export Habits…** and **Import Habits…**, each a full-width button with an icon, hover and pressed states like the Quit row (T-021).
- Export opens a standard macOS save dialog; Import a standard open dialog. The confirmation and error messages are standard macOS alerts.
- Confirmation: title **Replace your habits?** Message: **Your N habits (last checked off Oct 31) will be replaced by the M habits in “file name” (last checked off Mar 2). This can't be undone.** The dates are each side's most recent check-off, as month and day, with the year added when it isn't this year; a side with no check-offs says "(no check-offs)". Buttons: **Replace** (destructive) and **Cancel** (the default, so Return doesn't replace).
- Counts use the singular for one: "1 habit".

## 6. Use Cases

| Use case | Journey | How to verify |
| --- | --- | --- |
| UC-1 Take my history to a new Mac | Export on the old Mac, copy the file over, import it on the new Mac. Everything is as it was. | Manual test across two data folders; unit test of export then import |
| UC-2 Keep a copy | Export to a folder of my choosing, any time. | UI test with the dialog; unit test of the file |
| UC-3 Restore a copy | Import an earlier export over the current habits, confirming first. | UI test; unit test |

## 7. Behavior

### New

B.1 THE SYSTEM SHALL show Export Habits… and Import Habits… in Settings.

B.2 WHEN the user clicks Export Habits… THE SYSTEM SHALL open a save dialog with the file name "HabitCal Habits YYYY-MM-DD.json" (today's date).

B.3 WHEN the user saves THE SYSTEM SHALL write every habit, as shown in the app, to that file in the saved-habit-data format (section 10), and change nothing in the app.
Why: "as shown" covers the case where the last save failed: the export then rescues what's on screen.

B.4 WHEN the user exports with no habits THE SYSTEM SHALL write a file with an empty habit list.

B.5 WHEN the user clicks Import Habits… THE SYSTEM SHALL open an open dialog showing JSON files.

B.6 WHEN the user picks a file HabitCal can read and there are habits now THE SYSTEM SHALL ask for confirmation (section 5) before changing anything, naming each side's habit count and most recent check-off.
Why: there's no undo, and the likeliest mistake is restoring an older copy of the same habits, where the counts match and only the dates show what would be lost (review finding 1).

B.7 WHEN the user picks a file HabitCal can read and there are no habits now THE SYSTEM SHALL import it without asking.
Why: there's nothing to lose, and a new Mac is exactly this case.

B.8 WHEN the import goes ahead THE SYSTEM SHALL replace every habit with the file's, save them at once, and show them: the list, strips, streaks, and leaderboard all come from the imported habits.

B.9 THE SYSTEM SHALL accept for import exactly the files it would accept as its own saved data: any format version it knows, migrated as on load (CONTRACTS.md, "Saved habit data").

B.10 WHEN an import adds a habit that isn't due on the day shown THE SYSTEM SHALL leave it out of the list, as for any habit not due that day (T-036).

B.15 THE SYSTEM SHALL read or write only the file the user picks in the dialog, only while carrying out that export or import, and keep no access to it or its folder afterwards.
Why: the sandbox kept HabitCal to its own container (D-007); this is the smallest widening the feature needs (review finding 2).

### Unchanged

B.11 THE SYSTEM SHALL CONTINUE TO save habits only in its own container, in format version 1, unchanged by this task. Covered by: `savedFileIsSortedAndReadable`, `version1FixtureLoads`.

B.12 THE SYSTEM SHALL CONTINUE TO never write over a saved file it can't read. Covered by: `newerFormatIsNeverOverwritten`, `unreadableFileIsNeverOverwritten`.

B.13 THE SYSTEM SHALL CONTINUE TO make no network connections (D-007). Covered by: the build's entitlements (no network entitlement); manual review.

B.14 THE SYSTEM SHALL CONTINUE TO keep week start and launch at login as they are; an import doesn't touch them. Covered by: new test (B.8's).

## 8. Limits

- Largest file accepted for import: 10 MB. Years of daily check-offs for dozens of habits stay well under 1 MB (ARCHITECTURE.md, "Saving"); anything bigger isn't a HabitCal export.
- The exported file and the saved file have the same content for the same habits: export, then import, then export again gives an identical file.

## 9. Edge Cases and Errors

E.1 WHEN the user cancels either dialog, or the confirmation THE SYSTEM SHALL change nothing and write nothing.

E.2 WHEN the export can't be written (no permission, disk full, the folder vanished) THE SYSTEM SHALL show "Couldn't export your habits" with the reason macOS gives, and change nothing.

E.3 WHEN the picked file isn't a HabitCal habits file (not JSON, other fields, invalid values, or over 10 MB) THE SYSTEM SHALL show "This isn't a HabitCal habits file" and change nothing.

E.4 WHEN the picked file is in a newer format than this HabitCal knows THE SYSTEM SHALL show "This file is from a newer version of HabitCal. Update HabitCal to import it." and change nothing.

E.5 WHEN the picked file can't be opened (no permission, a cloud file not downloaded and unavailable offline) THE SYSTEM SHALL show "Couldn't open this file" with the reason macOS gives, and change nothing.

E.6 WHILE the saved habits can't be read (T-003 E.5) THE SYSTEM SHALL disable Import Habits… and Export Habits….
Why: importing would write over the unreadable file (D-004), and there are no habits loaded to export.

E.7 WHEN saving the imported habits fails THE SYSTEM SHALL show them anyway, with "Couldn't save — your last change may be lost" as for any failed save (T-003 E.6).

E.8 THE SYSTEM SHALL open each dialog and alert in front of all other windows and keep it there until the user answers; WHEN the popover closes while one is open THE SYSTEM SHALL keep it open and finish what the user chooses in it.
Why: HabitCal has no Dock icon or ⌘-Tab entry, so a dialog hidden behind another app's window couldn't be reached (review finding 4).

E.9 WHEN the user picks the file they are exporting to over an existing file THE SYSTEM SHALL let the save dialog ask whether to replace it, as macOS does.

E.10 THE SYSTEM SHALL make both buttons reachable by keyboard (with the Mac's Keyboard navigation on) and give them spoken labels "Export habits" and "Import habits"; the dialogs and alerts are standard and accessible.

E.11 WHEN the day changes while a dialog is open THE SYSTEM SHALL use the new day once the import finishes (streaks and today count from the current day), and the export's default name keeps the day the dialog opened.

## 10. Contracts

- **Exported habits file:** the same JSON as the saved-habit-data contract (format version 1 today, same fields and rules), UTF-8, extension `.json`. Relied on by: users' copies of their history, and every later HabitCal, which must import exports from every earlier version. Versioning: follows the saved-data contract; a newer export is refused by an older HabitCal (E.4), never misread.

## 11. Success Criteria

- Moving to a new Mac takes under a minute in HabitCal: one export, one import, and every habit, schedule, and check-off matches; imported the same day, every streak matches too.

## 12. Deferred

- Import from other habit apps (Streaks, Habitify exports) — each has its own format; wait for demand.
- A spreadsheet (CSV) export for people who want to chart their history — one-way only.
- Drag a habits file onto the popover to import — the buttons cover it.

## 13. Assumptions

- The popover may close when a file dialog opens (it closes when it loses focus, D-009). The user reopens it to see the result. E.8 is what matters; whether the popover can stay open is a design question for the MenuBarExtra.
- No default folder: the save dialog opens where macOS last saved.
- Export and Import are disabled together in the unreadable state; the Add button's rule is the precedent.

## Review

st-crit, 2026-10-31, CONCERNS. All four findings accepted: (1) the confirmation names each side's most recent check-off (section 5, B.6); (2) B.15 limits file access to the picked file, during the action; (3) streaks match only when imported the same day (sections 2, 11); (4) dialogs open in front (E.8).
