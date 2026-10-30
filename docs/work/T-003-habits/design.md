---
name: Habits
description: Habits with schedules and check-offs, the habit form, the strips, and the versioned data file.
task: T-003
rigor: Complex
trigger: "not revertible: creates the saved data format (habits.json) that every later version must read (D-004, D-006); also a contract"
date: 2026-10-29
review iteration: 0
status: Draft
---

# Tech Design: Habits

## 1. Context

T-002 built the shell: `AppModel` with `Screen` and `escape()`, `HabitListScreen` with an empty "Habits" area, `DayWatcher` as the only writer of `today`, and the Debug launch options. T-003 fills in the habit list, the form, the strips, and saving. T-004 (streaks) adds two numbers per row on top of this design's due-day rules.

## 2. Goals / Non-Goals

Goals:
- Every T-003 spec rule has a test point or a manual check (§13).
- `habits.json` format version 1, read by every later version: a fixture test pins it.
- Unreadable or newer-format data is never overwritten (D-004).

Non-goals:
- Streaks (T-004). The row leaves room for them on the right.
- Export, undo for delete, and reordering (spec Deferred).
- Any format migration: there is only version 1. The loader rejects any other version cleanly, so a future migration has a defined place to go.

## 3. Open Questions

None.

## 4. Requirements

### Spec Review

| Source | Direct claim | Changes it? |
| ------ | ------------ | ----------- |
| T-003 spec B.1–B.3 | Due day = weekday in the schedule in force that day, on or after the habit was added; a change applies from today; the last change of a day wins | No |
| T-003 spec B.4–B.7 | Done button toggles today; strip toggles due days ≤ today; future and not-due do nothing; strips follow the displayed month | No |
| T-003 spec B.8–B.14 | Form: add defaults, edit prefill, enable rule, save with trim, cancel, today's check-off removed if no longer due, duplicate names allowed | No |
| T-003 spec B.15–B.17 | Delete confirmation; delete removes everything; right-click Edit…/Delete… | B.17's menu is the native context menu (see §6) |
| T-003 spec B.18–B.20 | Saved at once; survives quit, crash, restart, update; local calendar dates; no network | No |
| T-003 spec E.1–E.9, Limits, §10 Contracts | Scrolling, discard on close, rollover, length limits, unreadable data, save failure, clock backward, accessibility, week start while editing; versioned data | No |
| T-002 B.15 | Week start orders the form's day buttons | Implemented here |
| ARCHITECTURE.md | `HabitStore` is the only reader/writer of `habits.json`; days stored as "YYYY-MM-DD" | No |
| D-004, D-006, D-007 | Versioned JSON, never overwrite unreadable, no network | No |
| CONVENTIONS.md | Rules in HabitCalKit; `Day` not `Date`; one `AppModel` method per change that saves | No |

## 5. Current System Audit

| Concern | Source evidence | Current behavior / gap |
| ------- | --------------- | ---------------------- |
| Screens and Esc | `HabitCal/AppModel.swift` `Screen { list, settings }`, `escape()` | Add `.form` |
| Habit area | `HabitCal/Views/HabitListScreen.swift` | Empty section and footer with the gear only |
| Main menu | `HabitCal/App/MainMenu.swift` | Quit only; text fields need an Edit menu for ⌘C/⌘V/⌘A/⌘Z |
| Launch options | `HabitCal/App/LaunchOptions.swift` | No data directory option yet |
| Week start | `AppModel.weekStart` | Ready for the form's day order |
| Icons | `Assets.xcassets`: ph-check, ph-pencil-simple, ph-plus, ph-trash | Present |

| Failure mode | Applicable / Not applicable / Checked—no issue / Accepted risk | Evidence |
| ------------ | -------------------------------------------------------------- | -------- |
| FM-001 Stale date | Applicable | Rows read `model.today`, which DayWatcher keeps current (E.3) |
| FM-002 Instants for days | Applicable | Check-offs and schedule starts are `Day`; JSON stores "YYYY-MM-DD" |
| FM-003 Saving over unreadable data | Applicable | `HabitStore` enters read-only `.unreadable`, and `save` refuses; Add is disabled |
| FM-004 Off-main UI state | Applicable | Saves are synchronous on the main actor; no background work |
| FM-005 Mac setting changes | Checked—no issue | Form reads `model.weekStart` |
| FM-006 Popover focus | Applicable | The form's text field must take focus and typing in a Dock-less app; UI test types into it |
| FM-007 Real date or data in tests | Applicable | New `-HabitCalDataDir`; unit tests use temporary directories |
| FM-008 Status item | Checked—no issue | Proven in T-002 |
| FM-009 Login item | Not applicable | — |

## 6. Proposed Design

**HabitCalKit** (pure, unit-tested):

- `Weekday` uses the existing 1–7 numbering (1 = Sunday). A schedule is a `Set<Int>` of weekdays.
- `ScheduleEntry { from: Day; days: Set<Int> }`.
- `Habit { id: UUID; name: String; note: String; addedOn: Day; schedule: [ScheduleEntry]; checkOffs: Set<Day> }`. The schedule is sorted by `from`; the first entry's `from` is `addedOn`.
  - `func days(on day: Day) -> Set<Int>`: the last entry with `from <= day`; empty before `addedOn` (B.1).
  - `func isDue(on day: Day) -> Bool` (B.1).
  - `func isDone(on day: Day) -> Bool`.
- `HabitDraft { name; note; days }` with `isValid` (B.10) and `trimmed` (B.11). Its limits are the constants `HabitDraft.maxNameLength = 40` and `maxNoteLength = 280`.
- `Habits` is a value type holding `[Habit]` in insertion order. Its mutating operations each take `today`, and each returns whether anything changed:
  - `add(_ draft:, today:) -> UUID` appends, with `addedOn = today` and `schedule = [from: today]` (B.11, B.14).
  - `update(_ id:, with draft:, today:)` sets the name and note. If the days differ from `days(on: today)`, it drops entries with `from >= today` and appends `{from: today, days}` (B.2, B.3). If today is now not due, it removes today's check-off (B.13).
  - `delete(_ id:)` (B.16).
  - `toggle(_ id:, on day:, today:)` is a no-op unless `day <= today && isDue(on: day)` (B.4–B.6).
- `StripDay` is an enum: `.done`, `.missed`, `.notScheduled`, `.future`, `.futureNotScheduled`, or `.blank` for slots past the month's end.
  - `Habit.strip(for: Month, today:) -> [StripDay]` always returns 31 entries (§5 of the spec).
  - Today is `.done` or `.missed`.
  - A day after today is `.future` or `.futureNotScheduled`, even if it has a check-off (E.7).
- `ScheduleLabel.text(for: Set<Int>) -> String` returns "Every day", "Weekdays" or "Weekends"; otherwise the short names in Monday-first order.
- `HabitStore` takes a directory URL and owns `habits.json` in it.
  - `func load() -> LoadResult`, where `LoadResult` is one of:
    - `.loaded(Habits)`;
    - `.empty`, when there's no file yet;
    - `.unreadable(reason)`, when decoding fails or `formatVersion` isn't 1.
  - `func save(_ habits: Habits) throws` encodes, then calls `Data.write(to:options: .atomic)`, which writes a temporary file and renames it. The store remembers whether its load came back `.unreadable`; if it did, `save` throws `HabitStoreError.readOnly` without touching the file (D-004, FM-003).
- File format v1, documented in CONTRACTS.md at close:

```json
{
  "formatVersion": 1,
  "habits": [
    {
      "id": "6F9619FF-8B86-D011-B42D-00CF4FC964FF",
      "name": "Run",
      "note": "5k loop around the park",
      "addedOn": "2026-10-01",
      "schedule": [ { "from": "2026-10-01", "days": ["fri", "sun"] } ],
      "checkOffs": ["2026-10-02", "2026-10-04"]
    }
  ]
}
```

  Weekdays are written as "sun" through "sat". Arrays are sorted when written, so files diff cleanly. Unknown keys are ignored when read, so a later version can add fields while keeping `formatVersion` at 1.

**App:**

- `LaunchOptions` gains `dataDirectory`. It's `-HabitCalDataDir path` in Debug; otherwise `Application Support/HabitCal/` in the container, created on first save.
- `AppModel` gains:
  - **State:** `habits: Habits` (`private(set)`) and `dataState`, which is `.ok`, `.unreadable(path)` (E.5) or `.saveFailed` (E.6, cleared by the next successful save). `Screen` gains `.form(HabitForm)`, where `HabitForm { mode: .add | .edit(UUID); draft: HabitDraft; confirmingDelete: Bool }`.
  - **Methods:** `openAddForm()`, `openEditForm(_:)`, `openDeleteConfirmation(_:)`, `saveForm()`, `cancelForm()`, `deleteFromForm()`, `toggleToday(_:)`, and `toggle(_:on:)`. Each one that changes habits calls the `Habits` operation and then `persist()`. `persist()` calls `store.save` and updates `dataState`.
  - **`escape()`:** `.form` → back to the list (B.12).
  - **`resetForOpen()`:** already resets to `.list`, so closing the popover discards an open form (E.2).
- **Views:**
  - `HabitListScreen`: if `dataState == .unreadable`, it shows the E.5 message. Otherwise it shows a `ScrollView` of `HabitRow`, with a maximum height of the screen's visible height minus 330 pt so the popover never runs off-screen (E.1), plus the E.6 banner, the empty state, and the footer with "+ Add habit" and the gear.
  - `HabitRow`:
    - **Done button:** three states with their tooltips and spoken labels.
    - **Name and label:** with the pencil on hover.
    - **Right-hand space:** for T-004's streaks.
    - **`.contextMenu`:** Edit… and Delete….
    - **`StripView`:** 31 squares. It's one accessibility element with adjustable actions: the arrow keys move between days, and Space (activate) toggles (E.8).
  - `HabitFormScreen`:
    - **Header:** Cancel, the title, and Add/Save.
    - **Name field:** focused and selected on open, with `.onSubmit` for Return.
    - **Day buttons:** in `model.weekStart` order.
    - **Notes field** and the **hints**.
    - **Delete** and its confirmation.
    - **Length limits:** enforced in the bindings (E.4).
- **Right-click menu:** a native SwiftUI `.contextMenu` (an NSMenu) rather than the prototype's drawn menu. It opens at the pointer and closes on a choice, an outside click, or Esc (B.17), with no Esc handling of our own. It also gives VoiceOver the standard "Show menu" action.
- **Esc in text fields:** the field editor handles `cancelOperation` itself (T-002 design finding 12). `HabitFormScreen` adds `.onExitCommand { model.escape() }` on the form, which fires from a focused text field. `PopoverHostingController.cancelOperation` still covers the unfocused case. The UI test `escapeInFormReturnsToList` types Esc with the name field focused.
- `MainMenu` gains an Edit menu: Undo, Redo, Cut, Copy, Paste, and Select All, with standard selectors.

| New state | Owner | Lifetime | Persist? | Why |
| --------- | ----- | -------- | -------- | --- |
| `habits` | AppModel (value), saved via HabitStore | Forever | `habits.json` | B.18 |
| `dataState` | AppModel | Process | No | E.5, E.6 |
| `HabitForm` inside `Screen.form` | AppModel | Until saved, cancelled, or the popover closes | No | E.2 |

| Operation | Triggers | Caller | Boundary | Handler/event | Registration | Consumer/state | Restore/cleanup | Test | Evidence |
| --------- | -------- | ------ | -------- | ------------- | ------------ | -------------- | --------------- | ---- | -------- |
| Load at launch | app start | AppDelegate | disk | `HabitStore.load` | `applicationDidFinishLaunching` | `habits`, `dataState` | — | Integration: store fixtures; UI: `habitsSurviveRelaunch` | B.18, E.5 |
| Add habit | "+ Add habit", Add/Return | HabitListScreen, HabitFormScreen | — then disk | `openAddForm`, `saveForm` | SwiftUI | `habits`, file | form discarded on close | Unit: `Habits.add`; UI: `addingAHabitShowsItWithItsScheduleLabel` | B.8, B.10, B.11, B.14 |
| Edit habit | name click, Edit… | HabitRow | — then disk | `openEditForm`, `saveForm` | SwiftUI | same | same | Unit: schedule change rules; UI: `editingAHabitRenamesItAndChangesItsDays` | B.2, B.3, B.9, B.13 |
| Delete habit | Delete, Delete… | HabitFormScreen, HabitRow | disk | `deleteFromForm` | SwiftUI | same | — | UI: `deletingAHabitAsksFirstThenRemovesIt` | B.15, B.16 |
| Toggle today | done button | HabitRow | disk | `toggleToday` | SwiftUI | same | — | Unit: toggle rules; UI: `checkingOffTodayFillsTheButtonAndTodaysSquare` | B.4 |
| Toggle a past day | strip square | StripView | disk | `toggle(_:on:)` | SwiftUI | same | — | UI: `fixingAMissedDayInTheStrip` | B.5, B.6, B.7 |
| Save | any change | AppModel.persist | disk | `HabitStore.save` | — | `dataState` | atomic replace | Integration: atomic save, read-only refusal | B.18, E.6, D-004 |

| Guarantee | Mechanism | Owner | Linearization point | Failure behavior | Proof |
| --------- | --------- | ----- | ------------------- | ---------------- | ----- |
| Never overwrite unreadable data | Load marks the store read-only; `save` throws | HabitStore | The `readOnly` check in `save` | Add disabled; E.5 message | Integration: `unreadableFileIsNeverOverwritten`, `newerFormatIsNeverOverwritten` |
| A change is on disk when the UI shows it | `persist()` runs synchronously after each mutation | AppModel | `Data.write(.atomic)` returns | E.6 banner; change kept in memory | Integration + UI relaunch |
| A crash can't leave a half-written file | Atomic write (temp file + rename) | HabitStore | The rename | Old file intact | Integration: `saveReplacesTheFileWhole` |

| Boundary | Concurrent event | Invariant | Linearization point | Recovery |
| -------- | ---------------- | --------- | ------------------- | -------- |
| Popover closes with the form open | user clicks outside | Nothing half-saved | Saving happens only in `saveForm` | Form discarded (E.2) |
| Date changes with the form open | midnight | Save uses the new today | `saveForm` reads `model.today` | — |
| Two copies running | — | Single instance (T-002 E.2) | — | — |

### Red Flags Audit

| Red flag | Present? | If present, why acceptable |
| ---------------------- | -------- | -------------------------- |
| Shallow module | No | Each `Habits` operation owns its rules (schedule cut-over, today's check-off cleanup); `AppModel` methods are one call plus `persist()` |
| Information leakage | No | The JSON shape stays in `HabitStore`'s private Codable DTOs; the model types aren't Codable |
| Temporal decomposition | No | Due-day logic has one home, `Habit.isDue`, used by the strip, the toggles, and T-004 |
| Pass-through method | No | — |

## 7. Interface Contract

| Interface | Inputs | Output | Errors | Async? |
| --------- | ------ | ------ | ------ | ------ |
| `Habit.isDue(on:)` | `Day` | Bool | — | No |
| `Habits.add/update/delete/toggle` | draft or id, day, today | UUID or Bool changed | — | No |
| `Habit.strip(for:today:)` | `Month`, `Day` | `[StripDay]`, count 31 | — | No |
| `ScheduleLabel.text(for:)` | `Set<Int>` | String | — | No |
| `HabitStore.load()` | — | `.loaded`, `.empty`, or `.unreadable(String)` | — | No |
| `HabitStore.save(_:)` | `Habits` | — | `readOnly`, file errors | No |

All HabitCalKit types are `Sendable` values; `HabitStore` is a final class confined to the main actor by its only caller.

## 8. Data Model & Persistence

- **File:** `habits.json` in the container's `Application Support/HabitCal/`. It's created on the first save; a missing file loads as `.empty`.
- **Format:** version 1, as in §6. A field added later is optional when read. A change that old versions would misread raises `formatVersion`, and old versions then show E.5 instead of overwriting.
- **Older builds:** there are none before v1. A build one version older than a future v2 file reads `formatVersion: 2` as unreadable, shows E.5, and doesn't write. That's the downgrade guarantee.
- **Fixture test:** a hand-written v1 file in the test bundle must decode to known habits. It pins the contract.
- **Retention:** habits stay until deleted. Deleting removes them from the file on the next save.

## 9. Capabilities & Security

No new entitlements: the container's Application Support is writable in the sandbox. Input from disk is decoded defensively: unknown weekday strings or invalid dates make the file unreadable (E.5), never a crash. No network (D-007).

## 10. macOS Versions and Appearance

| Variant | Difference from baseline | Verified how |
| ------- | ------------------------ | ------------ |
| Dark mode, Increase Contrast | Strip colors use system green and red with opacity, plus outlines for future days | Manual: habits look |
| VoiceOver | Strip is one adjustable element | UI test labels + manual VoiceOver |
| Later macOS, Intel | None | — |

## 11. Alternatives / Reuse / Proportionality

| Checked | Stdlib / native / existing dep / new dep | Covers? | Why not | Ceiling / upgrade path |
| ------- | ---------------------------------------- | ------- | ------- | ---------------------- |
| SwiftData | native | Yes | D-006 | — |
| Codable directly on model types | stdlib | Yes | It ties the file format to the model's Swift shape; a rename would silently change the contract. Private DTOs keep the format explicit | — |
| Prototype's drawn right-click menu | custom | Yes | Native `.contextMenu` gets pointer placement, dismissal, Esc, and VoiceOver for free | — |
| Debounced or background saving | Foundation | Yes | The file is tiny; synchronous saves make B.18 trivially true | Move off-main if saves ever exceed ~10 ms |

| Rare case | Cost to support | Requirement change that deletes it | Recommend |
| --------- | --------------- | ---------------------------------- | --------- |
| Clock moved backward (E.7) | None: falls out of the `day <= today` rules | — | Keep |

## 12. Implementation Slicing Strategy

1. **Model and store:** HabitCalKit `Habit`, `Habits`, `HabitDraft`, `ScheduleLabel`, `StripDay`, and `HabitStore` with fixtures, all unit- and integration-tested. App: load at launch, `-HabitCalDataDir`, and the rows (name, label, done button, strip) for existing data. Demo: a UI test seeded with a v1 file shows its habits, and checking off today persists across a relaunch.
2. **Form:** add, edit, and delete; the context menu; the Edit menu; Esc in the form; and the hints. Demo: add/edit/delete UI tests.
3. **Errors and edges:** the E.5 unreadable state, the E.6 banner, scrolling, and accessibility labels. Demo: UI tests with an unreadable and a newer-format file; manual checks.

## 13. Testing Strategy

| Test | Kind | Spec rules proved | Regression prevented |
| ---- | ---- | ----------------- | -------------------- |
| `habitIsDueOnlyOnScheduledWeekdaysFromTheDayItWasAdded` | unit | B.1 | Due before creation |
| `scheduleChangeAppliesFromTodayAndKeepsPastDays` | unit | B.2 | Retroactive misses |
| `secondScheduleChangeTheSameDayReplacesTheFirst` | unit | B.3 | Stacked entries |
| `togglingOnlyWorksOnDueDaysUpToToday` | unit | B.4–B.6 | Future check-offs |
| `stripShowsDoneMissedNotScheduledAndFutureForTheMonth` | unit | B.7, §5 table, E.7 | Wrong squares |
| `droppingTodayFromTheScheduleRemovesTodaysCheckOff` | unit | B.13 | Orphan check-off |
| `draftNeedsANameAndADay` / `draftTrimsNameAndNote` | unit | B.10, B.11 | — |
| `scheduleLabelNamesCommonSchedulesAndListsOthersMondayFirst` | unit | §5 label | — |
| `version1FixtureLoads` | integration | Contract | Format drift |
| `savedHabitsLoadBackUnchanged` | integration | B.18, B.19 | Lossy encoding |
| `missingFileLoadsEmpty` | integration | — | Crash on first run |
| `unreadableFileIsNeverOverwritten` / `newerFormatIsNeverOverwritten` | integration | E.5, D-004 | FM-003 |
| `saveReplacesTheFileWhole` | integration | B.18 | Torn writes |
| `addingAHabitShowsItWithItsScheduleLabel` | UI | UC-1, B.8, B.10, B.11 | — |
| `checkingOffTodayFillsTheButtonAndTodaysSquare` | UI | UC-2, B.4 | — |
| `fixingAMissedDayInTheStrip` | UI | UC-3, B.5, B.7 | — |
| `editingAHabitRenamesItAndChangesItsDays` | UI | UC-4, B.9, B.2 hint | — |
| `deletingAHabitAsksFirstThenRemovesIt` | UI | UC-5, B.15–B.17 | — |
| `habitsSurviveRelaunch` | UI | UC-6, B.18 | — |
| `escapeInFormReturnsToList` (name field focused) | UI | B.12 | Esc swallowed by the field editor |
| `unreadableDataShowsMessageAndDisablesAdd` | UI | E.5 | FM-003 |
| `emptyListShowsPrompt` | UI | §5 empty state | — |
| `habitControlsHaveSpokenLabels` | UI | E.8 | — |
| Manual: habits look in light/dark/Increase Contrast; scrolling with many habits; VoiceOver strip adjust; save failure banner (make the folder read-only); ⌘C/⌘V in the form | manual | E.1, E.6, E.8, §5 | Visual and OS-level |

E.2, E.3, E.4, E.9, B.14, B.19, and B.20 follow from the structure: E.2 from `resetForOpen`, E.3 from rows reading `model.today`, E.4 from the binding clamp, E.9 from computed day order, B.14 from no uniqueness check, B.19 from `Day` storage, and B.20 from D-007's sandbox. The unit tests above cover E.4 (`draft` limits) and B.19 (`savedHabitsLoadBackUnchanged` round-trips days as strings).

## 14. Rollout

Direct ship. The first release writes format version 1.

## 15. Reviewer Feedback

| \#  | Finding | Severity | Cost to accept | Decision | Rationale | Next step | Arch? | Source |
| --- | ------- | -------- | -------------- | -------- | --------- | --------- | ----- | ------ |

## 16. Lasting Changes

| Change | Goes to |
| ------ | ------- |
| `habits.json` format v1, its versioning rules, and the fixture test | CONTRACTS.md (created at close) |
| HabitCalKit types (Habit, Habits, HabitDraft, ScheduleLabel, StripDay, HabitStore) and the data directory | ARCHITECTURE.md |
| "Every habit change goes through an AppModel method that calls `persist()`" (already a rule) and "the JSON shape lives in HabitStore's private DTOs" | CONVENTIONS.md |
| Esc in text fields uses `.onExitCommand`; unfocused Esc uses `cancelOperation` | CONVENTIONS.md, Boundaries |
| Native `.contextMenu` over a drawn menu | ARCHITECTURE.md note |
| `-HabitCalDataDir` launch option | TESTING.md |
| Manual tests for habits | docs/manual-tests/habits.md |
