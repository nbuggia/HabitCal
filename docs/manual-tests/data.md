# Manual Tests: Export and Import

**Why manual:** the system's save and open panels and alerts run out of process, so UI tests answer them through Debug switches instead (T-035).

## Export from Settings

**Setup:** a few habits.

1. Open Settings, click Export Habits….
2. Save to the Desktop, then export again to the same name.

**Expect:** the HabitCal panel closes first and the menu bar icon's highlight clears; the save dialog is in front of every window, named "HabitCal Habits <today>.json"; the second save asks to replace the file. The file opens in a text editor as a HabitCal habits file (formatVersion 2).

## Export errors

1. Export to a folder you can't write to (e.g. a read-only disk image).

**Expect:** "Couldn't export your habits" with macOS's reason; nothing changes in HabitCal.

## Import from Settings

**Setup:** the export above, then change a habit.

1. Click Import Habits…, pick the export.
2. In the confirmation, press Return. Then import again and press Esc. Then import again and click Replace.

**Expect:** the open dialog shows JSON files; the confirmation names both counts and last check-offs ("on all your Macs" with iCloud on); Return cancels; Esc cancels (or note if it doesn't); Replace restores the exported habits.

## Import errors

1. Pick a non-HabitCal JSON file. 2. Pick an iCloud Drive file that isn't downloaded, with Wi-Fi off.

**Expect:** "This isn't a HabitCal habits file"; "Couldn't open this file" with macOS's reason. Nothing changes.

## VoiceOver and Release

1. With VoiceOver on, move to the Data buttons. 2. Run `codesign -d --entitlements - <Release build>/HabitCal.app`.

**Expect:** "Export habits" and "Import habits" are read; the Release entitlements include com.apple.security.files.user-selected.read-write.
