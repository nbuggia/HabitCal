---
name: Export and import tech design
description: Export habits to a file and import (replace) them from Settings, through system file dialogs, in the sandbox
task: T-035
rigor: Complex
trigger: "not revertible: import replaces saved data; contract: the exported file is a format later versions must read; risky ground: a new sandbox entitlement (user-selected files)"
date: 2026-11-01
review iteration: 2
status: Approved
---

# Tech Design: Export and Import Habit Data

## 1. Context

The spec (Approved 2026-10-31, `spec.md`) adds Export Habits… and Import Habits… to Settings: export saves the habits to a file the user picks, and import replaces them after a confirmation. Since then, T-039 (iCloud sync) built most of what import needs:
- habits.json v2 and `HabitCodec`;
- `Habits.replaceAll(with:now:)`, which deletes the known habits and adds the file's as new habits;
- the Settings Data section;
- the rule that an import replaces habits on every Mac (T-039 B.13, B.14).

The spike (`spike/README.md`) showed that a save dialog from HabitCal comes to the front, and that HabitCal's own panel sits above it, so the panel must close first.

## 2. Goals / Non-Goals

Goals:
- Export writes the shown habits in the saved-data format (v2) to the picked file (B.1–B.4).
- Import accepts exactly what HabitCal would load as its own data, asks first when there are habits, and replaces them, everywhere when sync is on (B.5–B.9; T-039 B.13, B.14).
- Every error leaves the habits unchanged and says why (E.1–E.5); nothing is overwritten that can't be read (E.6).
- File access is only the picked file, only during the action (B.15).

Non-Goals:
- Merging on import, a backup of what an import replaced, exporting settings, any other format (spec Not Doing).
- Exporting deleted habits: the file holds what's shown. An import adds new habits anyway (T-039).
- Remembering a folder, or keeping access to it (B.15).

## 3. Open Questions

- Clicking Save and writing the file wasn't run in the spike (nobody clicked). It's a manual check in slice 1. The entitlement and dialog APIs are standard, so the risk is low.

## 4. Requirements

### Spec Review

| Source | Direct claim | Changes it? |
| ------ | ------------ | ----------- |
| T-035 spec B.1–B.4 | Buttons; save dialog named "HabitCal Habits YYYY-MM-DD.json"; writes every habit as shown in the saved-data format; empty list allowed | New |
| T-035 spec B.5–B.10 | Open dialog for JSON; confirm when there are habits (counts and each side's latest check-off); none → import without asking; replace, save, show; accept what load accepts; not-due habits leave the list (T-036) | New |
| T-035 spec B.15 | Only the picked file, only during the action | New entitlement |
| T-035 spec E.1–E.11, Limits | Cancel changes nothing; write/read errors; not a HabitCal file; newer format; disabled while unreadable; failed save shows the usual banner; dialogs in front; overwrite prompt; keyboard and labels; day change; 10 MB | New |
| T-039 spec B.13, B.14 | Import replaces habits on every Mac; the confirmation says "on all your Macs" when sync is on | New (built here) |
| T-039 design §6 | `replaceAll` deletes shown habits and adds the file's under new IDs | Used as is |
| CONTRACTS.md "Saved habit data" (v2 after T-039) | The format and its versioning | Export carries it; a new "Exported habits file" contract |
| D-007 | Sandbox, no network entitlement | Refined: user-selected read-write files |
| CONVENTIONS.md "Only HabitStore touches the data file" | | Kept: export and import go through HabitStore's encode/decode, never touching habits.json |

## 5. Current System Audit

| Concern | Source evidence | Current behavior / gap |
| ------- | --------------- | ---------------------- |
| Settings layout | `SettingsScreen.swift`: About, General, Data (`SyncStatusRow`), Divider, Quit | Data section exists (T-039 slice 2) |
| Disabled state | `AppModel.canAddHabits` (false while unreadable) | Reused for both buttons (E.6) |
| Closing the panel | `AppModel.closePopover`, set by `PanelController` (cancelOperation, T-029) | Reused before dialogs |
| File format | `HabitStore.decodeFile` (v1, v2, else error), `save` writes `FileV2` | Needs public encode/decode of a file's bytes, with errors that tell "newer" from "invalid" |
| Replace | `Habits.replaceAll(with:now:)` (T-039) | Exists and is unit-tested |
| Change notification | `AppModel.persist(_ ids:)` → `habitsDidChange` → HabitSync | Import passes every changed ID |
| Labels | `HabitLabels` in HabitCalKit | Confirmation text goes there |
| Entitlements | Debug: `HabitCal.entitlements`; Release: build setting `ENABLE_APP_SANDBOX` only | Add user-selected read-write to both |
| UI tests | Can't drive the system save/open panels, which run out of process (remote view service) | Debug seams needed for the app path |

| Failure mode | Applicable / Not applicable / Checked—no issue / Accepted risk | Evidence |
| ------------ | -------------------------------------------------------------- | -------- |
| FM-001 date goes stale | Checked — no issue | The file name uses `model.today` when the dialog opens; import uses `model.today` when applied (E.11) |
| FM-002 instants for days | Checked — no issue | Days stay `Day`; the file is the v2 format |
| FM-003 saving destroys unreadable data | Applicable | Both buttons disabled while unreadable (E.6); an unreadable or newer file is refused before anything changes (E.3, E.4) |
| FM-004 UI state off main | Applicable | Dialogs and alerts run on the main actor; file I/O is small and synchronous there, under 10 MB, like saves today |
| FM-005 settings change | Not applicable | |
| FM-006 popover focus | Applicable | The panel closes before the dialog opens (spike), so no focus fight; reopening resets to the list (T-002 B.4) |
| FM-007 tests on real data | Applicable | UI tests use the Debug seams writing inside the test data folder, never the user's files |
| FM-008 status item | Not applicable | |
| FM-009 login item | Not applicable | |
| FM-010 text field | Not applicable | |
| FM-011 SVG | Checked — no issue | New Phosphor icons (export, import) are single-path SVGs like the others |
| FM-012 untested platform claim | Applicable | The dialog's position was spiked; the write is a slice 1 manual check |

## 6. Proposed Design

```
SettingsScreen (Data) ── Export / Import buttons ──▶ AppModel.exportHabits() / importHabits()
                                                        │ closePopover(then:), dialog once the panel is gone:
                                                        ▼
                                              FileDialogs (app target, main actor)
                         NSSavePanel / NSOpenPanel / NSAlert ── picked URL ──▶ read or write that file only
                                                        │
                                   HabitStore.exportData / HabitStore.importHabits (HabitCalKit)
                                                        │
                                   AppModel.applyImport → Habits.replaceAll → persist(ids) → HabitSync
```

**HabitCalKit**
- `HabitStore.exportData(_ habits: Habits) throws -> Data`: the v2 file bytes of `habits.all` (shown only), through the same `FileV2` encoder `save` uses. One format.
- `HabitStore.importHabits(from url: URL) throws -> Habits`, the one import call. It checks the file's size (`fileSizeKey`) **before reading**, then reads and decodes with the same decoder as load, so it accepts exactly what load accepts (B.9). `ImportError`:
  - `.cantOpen(String)`, with macOS's reason (E.5);
  - `.notHabitCal`: over `importLimit` (10 MB, named constant), not JSON, other fields, invalid values, or **no `formatVersion`** (E.3). `decodeFile` today calls a missing version "newer", so the split treats missing as invalid;
  - `.newerFormat(Int)`, for a `formatVersion` above 2 (E.4).
- `HabitLabels.exportFileName(today:)` gives "HabitCal Habits 2026-11-01.json".
- `HabitLabels.importConfirmation(current:incoming:fileName:syncOn:today:)` gives the title and message (spec §5; T-039 B.14).
- `HabitLabels.lastCheckOff(_ habits:today:)` gives "last checked off Oct 31", with the year when it isn't this year, or "no check-offs". It counts only shown habits and only `done` checks (v2 keeps unchecks and deleted records). Counts use "1 habit".
- `Habits.replaceAll(with:now:)` returns the IDs it deleted and added (`@discardableResult Set<UUID>`), so `applyImport` passes exactly those to sync.

**App target**
- `FileDialogs` (`App/FileDialogs.swift`, `@MainActor`), the only code that shows file panels or alerts:
  - `chooseExportURL(name:) -> URL?`
  - `chooseImportURL() -> URL?` (allowed type `.json`)
  - `confirmReplace(title:message:) -> Bool` (Replace with `hasDestructiveAction`, Cancel as the default button, so Return doesn't replace)
  - `showError(title:reason:)`
  - Each one first calls `NSApp.activate()` and uses the modal-panel level (spike). They run app-modal with `runModal()`, which blocks only the main run loop, as macOS's own dialogs do.
- **Closing the panel first.** `closePopover` takes a continuation: `closePopover(then:)`. `PanelController` sends `cancelOperation` as today, and holds one continuation (`pendingAfterClose`). A new request replaces the old one; the slot is cleared when the panel becomes visible again, so a reopened panel never fires a stale dialog, and cleared before it runs. When the occlusion observer sees `!window.isVisible`, it hands the continuation off with `DispatchQueue.main.async`, so the modal starts after the close has finished rather than inside the notification (T-029: the icon highlight is fragile around closing). If the panel is already closed, it runs at once. The panel can't linger over the dialog (spike: it sits above modal panels).
- `AppModel.exportHabits()`:
  - guards `canAddHabits`;
  - calls `closePopover(then:)`, and in the continuation: `dialogs.chooseExportURL(name:)`;
  - writes `HabitStore.exportData` with `.atomic`;
  - on failure, `showError("Couldn't export your habits", error.localizedDescription)` (E.2).
- `AppModel.importHabits()`:
  - guards `canAddHabits` and closes the panel as above;
  - `dialogs.chooseImportURL()` → `HabitStore.importHabits(from:)` → its three errors map to the E.3, E.4, and E.5 messages;
  - if `habits.all` isn't empty → `confirmReplace`;
  - then `applyImport(incoming)`.
- `AppModel.applyImport(_ incoming: Habits)`:
  - `habits.replaceAll(with: incoming.all, now: now())`;
  - `persist(` the IDs `replaceAll` returned `)`, so HabitSync sends them (T-039 B.13);
  - `selectedDay = nil`, so the list shows today.
- `syncOn` for the wording is `syncStatus != .off`.
- **Test seams (Debug only, and only under `-HabitCalDataDir`, FM-007).** The sandboxed app and the test runner can't read each other's folders (TESTING.md), so:
  - `-HabitCalExportTo name` makes the save dialog return `name` inside the test data folder;
  - `-HabitCalImportFile base64` makes the app write those bytes to a file in the test data folder, and the open dialog returns it, like `-HabitCalSeedData`;
  - `-HabitCalImportFrom name` returns an earlier export from the same folder;
  - the value `cancel` for any of them makes the dialog return nil (E.1);
  - `-HabitCalConfirmImport yes|no` answers the confirmation.
  - Export is proved inside the app: export, change the list, import the export, and see it restored.
- **Settings:** two rows under the status row in the Data group, "Export Habits…" and "Import Habits…". They're full-width `.hover` buttons with Phosphor `export` / `download-simple` icons, disabled when `!canAddHabits`, with spoken labels "Export habits" / "Import habits" (E.10).
- **Entitlement:** `com.apple.security.files.user-selected.read-write`, set one way in both configurations: the build setting `ENABLE_USER_SELECTED_FILES = readwrite`, which Xcode merges into the signed entitlements (as it does `ENABLE_APP_SANDBOX` today). `HabitCal.entitlements` isn't edited. No security-scoped bookmarks are kept (B.15).

| New state | Owner | Lifetime | Persist? | Why |
| --------- | ----- | -------- | -------- | --- |
| None | | | | Dialog results are local to the call; nothing is remembered (B.15) |

| Operation | Triggers | Caller | Boundary | Handler/event | Registration | Consumer/state | Restore/cleanup | Test | Evidence |
| --------- | -------- | ------ | -------- | ------------- | ------------ | -------------- | --------------- | ---- | -------- |
| Export | Export Habits… | `SettingsScreen` → `AppModel.exportHabits` | app → file system (user-selected) | `FileDialogs.chooseExportURL`, `HabitStore.exportData`, `Data.write` | button in Settings | the picked file | none | Kit: `exportWritesShownHabitsInTheSavedFormat`; UI (slice 2): `testExportThenImportRestoresTheList`, `testExportCancelledWritesNothing`; manual: real dialog, Save, Replace prompt | `HabitStore.save` already encodes `FileV2` |
| Import | Import Habits… | `SettingsScreen` → `AppModel.importHabits` | file system → app → HabitSync | `chooseImportURL`, `HabitStore.importHabits`, `confirmReplace`, `applyImport` | button | `habits`, habits.json, iCloud | panel reopens on the list | Kit: decode and label tests; UI: `testImportReplacesAfterConfirming`, `testImportCancelledChangesNothing`, `testImportWithNoHabitsDoesNotAsk`, `testImportRefusesANewerFile` (seams); manual: real dialog | `replaceAll` exists (T-039) |
| Close panel first | either button | `AppModel` | | `closePopover(then:)`, continuation run from the occlusion observer | `PanelController` | | the continuation runs at once when the panel is already closed | Manual: the panel is gone before the dialog appears, opened from Settings | T-029 `cancelOperation`, occlusion observer |

| Guarantee | Mechanism | Owner | Linearization point | Failure behavior | Proof |
| --------- | --------- | ----- | ------------------- | ---------------- | ----- |
| Nothing changes before the user confirms | Decode and validate fully, then confirm, then `replaceAll` | `AppModel.importHabits` | `applyImport` | Any error or Cancel returns before `applyImport` | UI tests (cancel, newer file); kit decode tests |
| Never overwrite unreadable data | Buttons disabled while unreadable; `persist` refuses then too | `AppModel` | `canAddHabits` | n/a | UI test `testExportAndImportDisabledWhileUnreadable` |
| One format | Export and load share `FileV2` | `HabitStore` | | | `exportThenImportGivesTheSameHabits` |
| Only the picked file | User-selected entitlement; no bookmarks | build settings, `FileDialogs` | | Access ends with the call | Review of entitlements; manual |

| Boundary | Concurrent event | Invariant | Linearization point | Recovery |
| -------- | ---------------- | --------- | ------------------- | -------- |
| Dialog open (modal) | iCloud changes arrive (HabitSync on the main actor) | Merges run while the modal run loop runs; the import replaces whatever is current at `applyImport` | `applyImport` | The confirmation counts may be a moment old. Accepted: counts are informative, and replace is the chosen behavior |
| Dialog open | Day changes | Import uses `today` at `applyImport`; the export name keeps the day the dialog opened (E.11) | | |
| Dialog open | User clicks the menu bar icon | The app-modal panel takes the clicks; the panel opens after the dialog closes | | |

### Red Flags Audit

| Red flag | Present? | If present, why acceptable |
| -------- | -------- | -------------------------- |
| Shallow module | No | `FileDialogs` hides AppKit panels, the activation, the level, and the test seams behind four calls |
| Information leakage | No | The file format stays in `HabitStore`'s private types |
| Temporal decomposition | No | One decoder for load and import |
| Pass-through method | Checked | `FileDialogs` adds activation, level, and seams; not a pass-through |
| Rules in the app target | No | Size limit, format, labels, and replace live in HabitCalKit |
| A second writer of habits.json | No | Export writes the picked file only; habits.json is still written only by `HabitStore.save` |

## 7. Interface Contract

| Interface | Inputs | Output | Errors | Async? |
| --------- | ------ | ------ | ------ | ------ |
| `HabitStore.exportData(_:)` | `Habits` | `Data` | encoding errors (none expected) | no |
| `HabitStore.importHabits(from:)` | file `URL` (size checked before reading) | `Habits` | `ImportError.cantOpen(String)`, `.notHabitCal(String)`, `.newerFormat(Int)` | no |
| `HabitStore.importLimit` | | 10 MB | | |
| `HabitLabels.exportFileName(today:)`, `importConfirmation(…)`, `lastCheckOff(…)` | | strings | | no |
| `FileDialogs.chooseExportURL/chooseImportURL/confirmReplace/showError` | | `URL?` / `Bool` | | `@MainActor`, modal |
| `AppModel.exportHabits/importHabits/applyImport` | | | | `@MainActor` |
| `NSSavePanel`, `NSOpenPanel`, `NSAlert`, `NSApp.activate()` | | | | main |

## 8. Data Model & Persistence

- habits.json isn't changed by this task.
- The exported file is the v2 saved-data format, holding shown habits only. It's a new contract, "Exported habits file", that follows "Saved habit data" versioning: any later version imports every earlier export, and an older version refuses a newer export (E.4).
- Import accepts v1 and v2 files (B.9). A v1 export from an earlier build loads through the v1 migration.
- No fixture is needed beyond the existing v1 and v2 fixtures, since import uses the same decoder. A test imports both.
- A round trip isn't byte-identical: an import adds new habits with new IDs and change times (T-039). What survives is names, notes, schedules, added dates, and check-offs (spec Limits, revised).

## 9. Capabilities & Security

- **New entitlement:** `com.apple.security.files.user-selected.read-write`. HabitCal can then read or write only a file the user picks in a system dialog, for as long as the process holds the URL. No bookmarks, so the access doesn't outlast the action (B.15).
- Still no network entitlement (D-007). A DECISIONS entry refines D-007 (proposed at close; drafted in pickup.md).
- An imported file is untrusted: the size check comes before reading it, and it's decoded with the same exact-keys and value checks as habits.json. Nothing is applied until it has decoded completely.

## 10. macOS Versions and Appearance

| Variant | Difference from baseline | Verified how |
| ------- | ------------------------ | ------------ |
| Later macOS | None expected; the dialogs are the system's | Run on macOS 27 |
| Intel | None | Universal build |
| Dark mode, Increase Contrast | System dialogs follow; the new icons are template images | Settings screenshot, both modes |
| VoiceOver | Spoken button labels; the dialogs and alert are the system's | Manual VoiceOver pass |

## 11. Alternatives / Reuse / Proportionality

| Checked | Stdlib / native / existing dep / new dep | Covers? | Why not | Ceiling / upgrade path |
| ------- | ---------------------------------------- | ------- | ------- | ---------------------- |
| `NSSavePanel`/`NSOpenPanel`/`NSAlert` | Native | Yes | Chosen | |
| SwiftUI `.fileExporter` / `.fileImporter` / `.confirmationDialog` | Native | Partly | Attached to a view in the MenuBarExtra panel, which must close first (spike) and would take the presenter with it | Revisit if HabitCal ever gets a normal window |
| Sheets on the panel | Native | No | The panel closes on resign (T-029) | |
| Share sheet / drag and drop | Native | No | Deferred in the spec | |

| Rare case | Cost to support | Requirement change that deletes it | Recommend |
| --------- | --------------- | ---------------------------------- | --------- |
| iCloud changes arriving while the confirmation is open | Re-reading counts after the dialog | Accept slightly old counts | Accept |

## 12. Implementation Slicing Strategy

Two slices, so no slicing plan.
1. **Export.** The entitlement in both configs, `FileDialogs` (save panel, error alert, seams), `HabitStore.exportData`, `exportFileName`, the Export row in Settings, and `closePopover(then:)`. Test gate: `exportWritesShownHabitsInTheSavedFormat`, `exportWithNoHabitsWritesAnEmptyList`, `exportFileNameUsesToday`. Demo: export to the Desktop by hand (the panel closes first and the icon un-highlights), and the file loads as a v2 habits file. The export UI tests need import, so they're in slice 2.
2. **Import.** `importHabits(from:)` with its errors, the confirmation labels including "on all your Macs" (T-039 B.14), `applyImport` through `replaceAll`, the Import button, and the import UI tests. Demo: import the slice 1 export over a changed list; cancel changes nothing; a newer file is refused. With sync on, the habits are replaced in iCloud too, which closes T-039's slice 5.

## 13. Testing Strategy

| Test | Kind | Spec rules proved | Regression prevented |
| ---- | ---- | ----------------- | -------------------- |
| `exportWritesShownHabitsInTheSavedFormat`, `exportWithNoHabitsWritesAnEmptyList`, `exportThenImportKeepsNamesSchedulesAndCheckOffs` (through `replaceAll`) | unit | B.3, B.4, Limits (round trip, revised) | Two formats drifting |
| `importAcceptsVersion1And2`, `importRefusesNewerFormat`, `importRefusesNonHabitCalFilesAndMissingVersion`, `importRefusesFilesOverTenMegabytesWithoutReadingThem`, `importReportsAFileItCantOpen` | unit (temp files) | B.9, E.3, E.4, E.5, Limits | Half-read or misread files |
| `replaceAllReturnsDeletedAndAddedIDs`, `lastCheckOffSkipsUnchecksAndDeletedHabits` | unit | T-039 B.13, B.6 | IDs missing from sync; wrong date in the confirmation |
| `exportFileNameUsesToday`, `importConfirmationNamesCountsAndLastCheckOffs`, `importConfirmationSaysAllYourMacsWhenSyncing`, `lastCheckOffAddsTheYearWhenNotThisYear` | unit | B.2, B.6, §5, T-039 B.14 | Wrong wording |
| `testExportThenImportRestoresTheList` (seams; slice 2) | UI | B.1, B.3, B.8 | Wiring |
| `testImportReplacesAfterConfirming` (also asserts week start is unchanged, B.14), `testImportCancelledChangesNothing` (confirmation and dialog cancel), `testExportCancelledWritesNothing` (importing the cancelled name shows "Couldn't open this file"), `testImportWithNoHabitsDoesNotAsk`, `testImportRefusesANewerFile` (seams) | UI | B.5–B.8, B.10, B.14, E.1, E.4 | Wiring, confirmation skipped |
| `testExportAndImportDisabledWhileUnreadable` | UI | E.6 | Overwriting unreadable data |
| `testDataButtonsHaveSpokenLabels` | UI | E.10 | |
| Manual: the panel is gone before the dialog appears; real save dialog (front, Save, the overwrite prompt, a read-only folder error); real open dialog (a non-JSON file, an iCloud Drive file not downloaded and offline); confirmation with Return (cancels); VoiceOver; `codesign -d --entitlements -` on a Release build shows user-selected read-write | manual (real boundary; system panels run out of process and UI tests can't drive them) | E.2, E.5, E.8, E.9, E.10, B.15 | Panel behavior |
| Manual with sync on: import on Mac A, Mac B shows the file's habits | manual | T-039 B.13 | |

E.7 (a failed save after import) is the existing save-failed path, covered by `manual-tests/habits.md` "A failed save". E.11 is covered by the design (today read at apply time) and isn't separately tested.

## 14. Rollout

Direct ship, no flag. Signing impact: one entitlement added to both configurations. T-005's Developer ID profile must allow it, which needs no portal capability, since it's a sandbox entitlement.

## 15. Reviewer Feedback

| \#  | Finding | Severity | Cost to accept | Decision | Rationale | Next step | Arch? | Source |
| --- | ------- | -------- | -------------- | -------- | --------- | --------- | ----- | ------ |
| 1 | "Next main-actor turn" doesn't wait for the panel to close; untested claim | MAJOR | Dialog hidden under the panel | ACCEPT | | `closePopover(then:)` from the occlusion observer; manual check | Yes | Pass 1 |
| 2 | UI tests can't read the export or seed an import file across the sandbox | MAJOR | Tests check nothing | ACCEPT | | Base64 import seam; prove export by importing it back; seams only under -HabitCalDataDir | | Pass 1 |
| 3 | Spec's "identical file" round trip can't hold after T-039 | MAJOR | Unmet rule | ACCEPT | | Spec Limits revised to content; test through replaceAll | Spec | Pass 1 |
| 4 | replaceAll returns nothing | MINOR | IDs missed by sync | ACCEPT | | Return Set<UUID>; test | | Pass 1 |
| 5 | Size checked twice and after reading; E.5 untested; missing version labelled newer | MINOR | Duplicate rule | ACCEPT | | One importHabits(from url:) | | Pass 1 |
| 6 | Entitlement set two ways | MINOR | Release drift | ACCEPT | | ENABLE_USER_SELECTED_FILES in both; codesign check | Yes | Pass 1 |
| 7 | B.14, dialog cancel, lastCheckOff on unchecks missing from §13 | MINOR | Untested rules | ACCEPT | | Added | | Pass 1 |
| 8 | Lasting Changes missing items | MINOR | Rules lost later | ACCEPT | | Added | | Pass 1 |
| 9 | Pending continuation has no lifetime | MINOR | Duplicate or stray dialogs | ACCEPT | | One slot: replaced, cleared on reopen and before running | | Pass 2 |
| 10 | runModal inside the occlusion notification | MINOR | Stuck icon highlight | ACCEPT | | Hand off with DispatchQueue.main.async; manual check includes the icon | | Pass 2 |
| 11 | Slice 1 test and cancel test can't observe their claims | MINOR | Gate can't run | ACCEPT | | Export UI tests move to slice 2; slice 1 gate is kit tests and the manual demo | | Pass 2 |
| 12 | §7 and the §6 diagram stale | MINOR | Wrong API for the implementer | ACCEPT | | Fixed | | Pass 2 |

## 16. Lasting Changes

| Change | Goes to |
| ------ | ------- |
| `FileDialogs` is the only code that shows file panels and alerts; it closes the panel first and activates the app | ARCHITECTURE.md (Components), CONVENTIONS.md (Popover) |
| Exported habits file: v2 saved-data format, shown habits only, `.json`; versioning follows saved data | CONTRACTS.md (new "Exported habits file") |
| Import limit 10 MB (`HabitStore.importLimit`) | code constant with comment; ARCHITECTURE.md |
| User-selected read-write files, no bookmarks | DECISIONS.md (refines D-007); ARCHITECTURE.md Boundaries |
| Debug seams `-HabitCalExportTo`, `-HabitCalImportFile` (base64), `-HabitCalImportFrom`, `cancel`, `-HabitCalConfirmImport`, only under `-HabitCalDataDir`; export proved by importing it back in the app (the sandbox walls off the runner) | TESTING.md |
| `closePopover(then:)`: one pending continuation, replaced by a newer request, cleared when the panel reopens, run asynchronously once the panel is really gone; dialogs start from it | ARCHITECTURE.md (The Popover), CONVENTIONS.md |
| Import errors: can't open / not a HabitCal file (incl. no version, over 10 MB, checked before reading) / newer format | CONTRACTS.md "Exported habits file" |
| Exports are v2 since T-039; a round trip keeps content, not IDs or bytes | CONTRACTS.md "Exported habits file" |
| The entitlement is a build setting in both configurations (`ENABLE_USER_SELECTED_FILES`) | ARCHITECTURE.md (Stack) |
| Trap: HabitCal's MenuBarExtra panel sits above modal panels (layer 101 vs 8); close it before any dialog | COMMON-FAILURE-MODES.md |
| Rejected: SwiftUI `.fileExporter`/`.fileImporter` from the panel | DECISIONS.md (with the D-007 refinement) or ARCHITECTURE.md |
| Manual tests for the real dialogs | docs/manual-tests/data.md (new) |
