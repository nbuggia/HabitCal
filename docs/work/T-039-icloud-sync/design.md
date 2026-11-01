---
name: iCloud sync tech design
description: Sync habits across the user's Macs through CloudKit (CKSyncEngine), merging by per-field and per-day change times
task: T-039
rigor: Complex
trigger: "not revertible: changes the saved data format (habits.json v2); contract: adds synced records other HabitCal versions read; risky ground: new iCloud entitlements and background concurrency"
date: 2026-11-01
review iteration: 2
status: Draft
---

# Tech Design: iCloud Sync Across Macs

## 1. Context

The customer wants their habits on every Mac they use, invisibly (D-010, spec approved 2026-11-01). The spike proved CloudKit works from the sandboxed app, development- and Developer ID-signed, with no network entitlement, and that `CKSyncEngine` starts (spike README). Today habits live only in `habits.json` v1, which has no notion of when anything changed, so two Macs' edits can't be merged without losing one (spec B.16).

## 2. Goals / Non-Goals

Goals:
- Every change on one Mac reaches the others, and changes from them are merged in, with no user action (B.1–B.5).
- Merging follows the spec's conflict table exactly and never drops a check-off (B.7–B.12, B.21), proved by unit tests of every row.
- HabitCal works exactly as today without iCloud (B.5, E.1–E.5), and older or newer HabitCal versions never corrupt each other's data (E.6, B.18).
- Settings shows one status line (section 5 of the spec).

Non-Goals:
- Garbage-collecting deleted-habit records in iCloud. They're a few hundred bytes each; collecting them safely needs every Mac to have seen the delete, which CloudKit can't tell us.
- Syncing settings, a sync switch, or any UI beyond the Settings line (spec Not Doing).
- Building import itself: T-035 builds it. This design gives HabitCalKit the "replace everywhere" operation (B.13) and wires it when T-035's code lands (§12).
- Real-time co-editing of the same field: the later change wins (spec).

## 3. Open Questions

- **Push delivery (B.2).** `CKSyncEngine` fetches on CloudKit pushes. The spike didn't prove that pushes arrive (one Mac). The design doesn't depend on it: a 60 s fetch backs it up (§6, "Fetch fallback"). Slice 2's manual check (CloudKit Console edit → change shows within a minute) records whether push works; if it does, the fallback stays as a safety net.
- **Release signing.** Xcode's command line couldn't make a Developer ID profile (spike). The release profile for `com.muchfiner.HabitCal` with iCloud is made at developer.apple.com by the customer, as for the spike. That's a T-005 step, not a blocker here.

## 4. Requirements

### Spec Review

| Source | Direct claim | Changes it? |
| ------ | ------------ | ----------- |
| T-039 spec B.1–B.6 | Sync without action; within 1 minute; fetch at launch, wake, back online; update in place; work without iCloud; never ask | New |
| T-039 spec B.7–B.9, B.8a, B.8b | First sync merges; same habit or same name → one copy; past days due only if due in both or checked; no times → most recent check-off wins | New |
| T-039 spec conflict table, B.10–B.12, B.21 | Per habit and per day; later change wins by when made; delete beats edits; import rows; form edits change only the touched field; order by date added; a merge never drops a check-off | New |
| T-039 spec B.13–B.15 | Import replaces everywhere; confirmation says so; delete everywhere | New (T-035's B.8 and confirmation change) |
| T-039 spec B.16 | Saving records change times and deletions | Changes CONTRACTS.md "Saved habit data" (v1 → v2) |
| T-039 spec E.1–E.11 | Unreadable → no sync; account switch merges; sign-out; iCloud data deleted → resend; full; newer format; time zones; check-off on a not-scheduled day kept; partial failure; quit with pending; VoiceOver | New |
| CONTRACTS.md "Saved habit data" | "any change to what is written bumps formatVersion… never writes over it" | Bumped to 2; rule kept |
| D-010 | CloudKit private database; local file stays the source; D-004's local rules hold | Implemented here |
| D-007 | No network entitlement | Unchanged (spike: none needed) |
| ARCHITECTURE.md "State and Persistence" | "Schedules: a change applies from today. Entries starting today or later are replaced… Today's check-off is removed if today is no longer due." | Kept for local edits; merges follow B.21 |
| CONVENTIONS.md "Only HabitStore touches the data file"; "Never make a network request" | | Kept: sync state goes in its own file owned by the sync component; CloudKit traffic is the system's |
| T-038 (AppModel `formStart`) | Each edit applied to the habit as it was at open | Changed: field-level (B.11) |

Sources with no relevant claims: TESTING.md (beyond FM-007's rule), PRD Feature sections other than Habits.

## 5. Current System Audit

| Concern | Source evidence | Current behavior / gap |
| ------- | --------------- | ---------------------- |
| Habit model | `Habit.swift`: `name`, `note`, `addedOn`, `schedule: [ScheduleEntry]`, `checkOffs: Set<Day>` | No change times, no record of unchecks or deletes |
| Habit operations | `Habits.swift`: `add`, `update` (replaces entries from today, drops today's check-off when no longer due), `delete` (removes), `toggle`, `replace` | Mutations erase history needed to merge |
| Due rule | `Habit.isDue(on:)` = schedule's weekday only | B.21 needs "or checked off" |
| Persistence | `HabitStore` v1: exact-keys check, `formatVersion == 1` else unreadable, atomic write, `canSave` gate | Only writer of habits.json; v2 needed |
| Change entry points | `AppModel`: `toggle`, `saveForm` (add), `updateDraft` (edit, live), `deleteFromForm`; each calls `persist()` | Single funnel: every local change already passes through `persist()` |
| Form | `AppModel.formStart: Habit?`, `updateDraft` re-applies the whole draft to it and `habits.replace`s | Would overwrite remote changes to other fields (B.11) |
| Clock | `TodaySource` gives `Day`; no instant clock exists | Change times need an injected instant clock |
| App wiring | `AppDelegate.init` builds `HabitStore`, `AppModel`, `PanelController`, `DayWatcher`; `LaunchOptions` Debug seams | Sync component is built here |
| Wake / timer | `DayWatcher`: wake notification, 60 s timer | Reused as triggers for fetch (B.3, fallback) |
| Signing | project.pbxproj: `CODE_SIGN_IDENTITY = "-"`, Manual, no entitlements file; `ENABLE_APP_SANDBOX` build setting | Needs an entitlements file and team signing (Debug: automatic, as the spike) |
| UI tests | `HabitCalUITestCase.launch` always passes `-HabitCalDataDir` | Usable as the "never sync" switch (FM-007) |

| Failure mode | Applicable / Not applicable / Checked—no issue / Accepted risk | Evidence |
| ------------ | -------------------------------------------------------------- | -------- |
| FM-001 date goes stale | Checked — no issue | Merges read `today` from `AppModel`, which `DayWatcher` keeps current |
| FM-002 instants for days | Applicable | Change times are instants by design (B.10); check-off keys and schedule `from` stay `Day`. Instants never stand for a calendar day |
| FM-003 saving destroys unreadable data | Applicable | Sync never starts while `dataState == .unreadable` (E.1); a record with a newer format is never merged or overwritten (E.6); `HabitStore` v2 keeps the exact-keys/newer-version gate |
| FM-004 UI state off main | Applicable | `CKSyncEngineDelegate` runs off the main actor; every touch of `AppModel` hops to `@MainActor` (§6 concurrency table) |
| FM-005 Mac settings change | Not applicable | No new settings read |
| FM-006 popover focus | Checked — no issue | Remote changes re-render in place (B.4); a focused strip leaving the list is the T-036 path, covered by `testEscStillClosesAfterTheFocusedStripLeavesTheList` |
| FM-007 tests on real data | Applicable | Sync is off whenever `-HabitCalDataDir` is set; the instant clock is injected; HabitCalKit tests never touch CloudKit |
| FM-008 status item in UI tests | Not applicable | |
| FM-009 login item | Not applicable | |
| FM-010 clamped value vs text field | Checked — no issue | A remote rename doesn't push into the form's `@State` text (B.11 keeps the touched field) |
| FM-011 SVG gradients | Not applicable | The status icon is a Phosphor line icon |
| FM-012 untested platform claim | Applicable | CloudKit, sandbox, Developer ID spiked; push delivery not proven → 60 s fetch fallback, manual check in slice 2 |

## 6. Proposed Design

Three parts, one boundary each:

```
AppModel (main actor) ──local change──▶ Habits (HabitCalKit: stamped, mergeable) ──▶ HabitStore v2 (habits.json)
     ▲                                        ▲  merge(remote)
     │ status, applyRemote                    │
HabitSync (app target) ── CKSyncEngine ── iCloud private DB, zone "Habits", one record per habit
     └── sync-state.json (engine state, first-sync flag), owned by HabitSync only
```

**1. HabitCalKit: a mergeable habit (pure Swift, every rule unit-tested).**
- Each habit keeps last-writer-wins registers: `name`, `note` (value + `changedAt`), `checks: [Day: Check]` where `Check` is `done: Bool` + `changedAt` (an uncheck is stored, B.10), `schedule: [Day: Entry]` keyed by `from` (days + `changedAt`; may be empty for merged past days, B.8a), `createdAt`, `deletedAt?`. `addedOn` stays a `Day`.
- The library keeps `importedAt?`.
- **Existence:** a habit is shown iff `createdAt >= importedAt` and (`deletedAt == nil` or `createdAt > deletedAt`). Delete beats every edit because edits never touch `createdAt`. An import re-creates its habits with `createdAt = importedAt`, which revives a deleted ID (conflict table, import rows).
- **Registers with a time older than `createdAt` are ignored**, so changes made before an import lose to it, and changes made after it apply on top. A nil time (v1 data) is never ignored by this rule.
- `Habits.all` holds only the habits shown; every stored record, deleted or hidden by an import included, lives in `Habits.records`, used only by `HabitStore`, the merge, and sync. Every screen (list, leaderboard, streaks) reads `all`, as today.
- **Due:** `isDue(day)` = the schedule's weekday or a live `done` check (B.21). `strip`, `Streaks`, and `Consistency` already go through `isDue`/`isDone`, so they follow.
- **Local operations** take `now: Date` and stamp what they change: `toggle`, `add`, `rename`, `setNote`, `setDays` (today's check-off still drops when today stops being due, as an uncheck at `now`), `delete` (sets `deletedAt`), `replaceAll(with:now:)` (import: sets `importedAt = now`, re-creates every file habit with `createdAt = now` and every register stamped at `now`).
- **Form edits:** `applyFormEdit(id, from: oldDraft, to: newDraft, todayDoneAtOpen:, today:, now:)` applies only the field that differs (B.11), and re-checks today when today's weekday comes back in the same form session (T-038). It lives in the kit so it's unit-tested.
- **`merge(_ remote: Habit)`, ongoing:** register by register, later `changedAt` wins; `deletedAt` = the later of the two; `createdAt` = the later; `addedOn` = the earlier. A nil time is older than any time. **Ties** (equal times, or nil and nil) break by a fixed rule: `done` beats not done, a non-empty schedule beats an empty one, then the larger encoded value. So merge is commutative, associative, and idempotent, and any order of arrival gives the same result.
- **`mergeFirstSync(local:remote:today:)`:** pairs habits by ID, then by normalized name (B.9: trimmed, case-folded), keeping the remote ID. Name pairing considers only habits shown on both sides, never a deleted or import-hidden record, so a habit deleted on one Mac can't delete a same-named live one on the other (B.7). For each pair:
  - check-offs and earlier `addedOn` as in `merge`;
  - current fields from the side changed last, or by B.8b, the most recent check-off, else remote;
  - schedule entries before today become the per-interval intersection of both histories (B.8a), and an entry at `today` carries the winner's current days, so the merged habit always has days in force today. Empty entries exist only before today;
  - the pair takes the **earlier** `createdAt`, and any register of either copy older than it is raised to it, so no check-off is hidden by the ignore rule (B.7, B.21). `merge` (ongoing) keeps "later `createdAt`", which is what makes an import win.
  - Unpaired habits are kept as they are.
- **Order (B.12):** sorted by `addedOn`, then `createdAt`, then ID: a fixed order, the same on every Mac.
- v1 data migrates with `createdAt` = `distantPast` plus the habit's position in the list in milliseconds, so its order holds and no v1 time can be later than a real one. Every `changedAt` is nil.

**2. HabitStore v2.** Same file, same atomic write and `canSave` gate.
- `formatVersion: 2` with the registers above, plus `importedAt`. Loads v1 (migrating in memory) and v2; anything newer, or keys either version never writes, is unreadable (D-004).
- The per-habit JSON is shared: `HabitCodec` encodes one habit, and the file is a list of them. That same encoding is the CloudKit record payload, so there's one format and one codec.

**3. HabitSync (app target), the only code that imports CloudKit.**
- Owns a `CKSyncEngine` on the private database, zone `Habits`.
- Record type `Habit`: recordName = habit UUID; fields `formatVersion` (Int) and `payload` (Bytes, the `HabitCodec` JSON).
- Record type `Library`: one record, `library`, with `formatVersion` and `importedAt`.
- Deleted habits stay as records with `deletedAt`. CloudKit deletes are never used, so an offline Mac's edit can't bring a habit back.
- **Start:** built in `AppDelegate` unless `dataState` is unreadable (E.1) or `-HabitCalDataDir` is set (FM-007). It loads `sync-state.json` (engine `State.Serialization`, the first-sync flag, the record system fields cache, the update-needed flag, `lastSynced`, `lastSentAt`), creates the zone on first send, and registers for remote notifications.
- **Record system fields cache** (`[recordName: encodedSystemFields]`): CKSyncEngine saves with `.ifServerRecordUnchanged`, so every save of an existing record must start from its last known server record. The cache is updated from every fetched and every successfully sent record, taken from `serverRecord` on a conflict, and cleared on a zone reset or account change. A record with no cached fields is built fresh (first send).
- HabitSync and its delegate methods are `@MainActor` (allowed for async delegate requirements), so `AppModel` is reached without hops.
- **Local change:** `AppModel.persist()` calls `sync.changed(ids)`, which adds pending record saves to the engine state.
- **`nextRecordZoneChangeBatch`:** for each pending habit, starts from its cached system fields (or a new record) and sets `formatVersion` and `payload` from the current habit.
- **`fetchedRecordZoneChanges`:**
  - decodes the payloads;
  - a record with a newer `formatVersion` sets status `.updateNeeded` and stops sending (E.6);
  - otherwise it calls `AppModel.applyRemote(habits, library)`, which merges and **saves before the event handler returns**. The engine writes its new change token right after each batch, so a batch that isn't saved by then would never be delivered again. It also queues a send for every habit whose merge result differs from what came in, which is how a winning local change gets back to iCloud.
- **No sends before the first sync finishes:** while the flag is false, `nextRecordZoneChangeBatch` returns nothing, so a local habit that name-pairs into a remote one is never uploaded under its own ID (a `SyncPolicy` rule).
- **First sync:** while the flag is false, each fetched batch goes through `mergeFirstSync` (merged and saved batch by batch, as above); the flag is set on `.didFetchChanges`. It's idempotent, so a batch seen twice after a crash merges to the same result. A Mac with nothing local merges the same way.
- **Newer format (E.6):** a skipped record sets the persisted update-needed flag. A build that starts with the flag set and now knows the format discards the engine state and fetches everything again (merging is idempotent), so the skipped records arrive.
- **`sentRecordZoneChanges` failures:**
  - `serverRecordChanged`: merge the server's payload, then re-queue.
  - `zoneNotFound` or `userDeletedZone`: recreate the zone and re-queue all records (E.4).
  - `quotaExceeded`: status `.full`, and the engine retries.
  - network: status `.waiting`.
  - others: status `.error(reason)`.
- **`accountChange`:**
  - `signIn` / `switchAccounts`: reset the engine state and the system fields cache, clear the first-sync flag, and re-queue every habit shown. The old account's deleted records aren't sent to the new account (E.2).
  - `signOut`: reset, status `.off`, and the local habits stay (E.3).
- **`stateUpdate`:** write `sync-state.json` atomically (E.10).
- **Fetch fallback:** `DayWatcher`'s wake notification and its 60 s timer also call `sync.fetchSoon()`, which runs `fetchChanges()` at most once every 50 s (B.2, B.3).

**AppModel changes.**
- Gets an injected `now: () -> Date` (from `LaunchOptions`; tests fix it) and `syncStatus: SyncStatus`.
- Every change method passes `now()` to the kit operation and then calls `persist()`, which saves and notifies sync.
- `applyRemote` merges, persists, and leaves `form`/`screen` alone, except that a form on a habit no longer shown closes (B.11).
- `updateDraft` calls `Habits.applyFormEdit` with the previous and new draft, so only the changed field is written and remote changes to other fields and habits stay (B.11). `formStart` keeps only today's done state at open, for the re-check in `applyFormEdit` (T-038).

**Sync decisions in the kit.** `SyncPolicy` in HabitCalKit is a pure function from an engine outcome (record decoded, newer format, `serverRecordChanged`, zone deleted, quota, network unavailable, other error, account signed in / out / switched, fetch finished) to actions (merge, re-queue IDs, reset state, set flags) and a `SyncStatus`. HabitSync maps `CKError` codes and engine events onto its inputs and performs the actions. So the decision rules behind E.2–E.6 are unit-tested, and only the CloudKit translation is left to manual checks.

**Settings.** A `SyncStatusRow` at the top of DATA (`SettingsScreen`). The text and spoken label come from `HabitLabels.syncStatus(_:lastSynced:)` in HabitCalKit.

| New state | Owner | Lifetime | Persist? | Why |
| --------- | ----- | -------- | -------- | --- |
| Per-field and per-day `changedAt`, unchecks, `createdAt`, `deletedAt` | `Habit` (HabitCalKit) | Forever | habits.json v2 and the iCloud payload | Merge (B.10, B.16) |
| `importedAt` | `Habits` | Forever | habits.json v2, `Library` record | Import everywhere (B.13) |
| Engine state, first-sync flag, record system fields cache, update-needed flag, `lastSynced`, `lastSentAt` | `HabitSync` | Until account change (the cache until a zone reset too) | `sync-state.json` in the container | Pending sends survive quit (E.10); conflict-free saves; first-sync rule (B.7); E.6 recovery; Settings line |
| `syncStatus` | `AppModel` | Process | No | Settings line |

| Operation | Triggers | Caller | Boundary | Handler/event | Registration | Consumer/state | Restore/cleanup | Test | Evidence |
| --------- | -------- | ------ | -------- | ------------- | ------------ | -------------- | --------------- | ---- | -------- |
| Local change → iCloud | check-off, add, edit, delete, import | `AppModel` methods → `persist()` | main actor → engine state | `nextRecordZoneChangeBatch` | `CKSyncEngine` created in `AppDelegate.init` | iCloud record | Engine state persisted at `stateUpdate` | Kit unit tests of stamping; manual two-Mac / Console | `AppModel.persist` is the single funnel today |
| iCloud → local | push, launch, wake, 60 s | CKSyncEngine; `DayWatcher` → `sync.fetchSoon()` | engine → main actor | `fetchedRecordZoneChanges` → `AppModel.applyRemote` | delegate set on engine | `habits`, saved | none | Kit merge tests; manual | `DayWatcher` already observes wake and runs a 60 s timer |
| First sync | first fetch after start or account change | HabitSync | as above | `mergeFirstSync` | flag in sync-state | `habits` | flag reset on account change | Kit tests B.7–B.9, B.8a, B.8b; manual on two Macs | |
| Conflict on send | `serverRecordChanged` | CKSyncEngine | engine → main actor | `sentRecordZoneChanges` | | merge + re-queue | | Kit merge tests; manual (edit offline on both) | |
| Zone deleted / data reset | `fetchedDatabaseChanges` deletion, `zoneNotFound` | CKSyncEngine | | recreate zone, re-queue all | | iCloud | | Manual (delete in CloudKit Console) | |
| Account change | sign in/out/switch | CKSyncEngine `.accountChange` | | `SyncPolicy` → reset state, status | | `syncStatus`, first-sync flag | sync-state and cache reset | `SyncPolicy` unit tests; manual (sign-out not run: accepted risk, spike) | Spike Q3 |
| Status shown | any of the above | HabitSync → `AppModel.syncStatus` | main actor | Settings re-render | | `SyncStatusRow` | | Kit label tests; UI test with `-HabitCalSyncStatus` (Debug) | |
| Field-level form edit | typing, day toggle | `HabitFormScreen` → `AppModel.updateDraft` | | `Habits.applyFormEdit` | | `habits` | `formStart` cleared on close | Kit tests; existing form UI tests | T-038 code |

| Guarantee | Mechanism | Owner | Linearization point | Failure behavior | Proof |
| --------- | --------- | ----- | ------------------- | ---------------- | ----- |
| No check-off lost to a merge (B.21) | Per-day registers; merge only compares `changedAt`; due includes live checks | HabitCalKit | `Habits.merge` returning | n/a (pure) | Unit test of every conflict-table row and B.8a |
| Same result on every Mac | Merge commutative, associative, idempotent | HabitCalKit | | | Property-style unit test: random edits merged in different orders agree |
| Delete wins; import revives | Existence rule on `createdAt`/`deletedAt`/`importedAt` | HabitCalKit | | | Unit tests of the table's delete and import rows |
| Nothing overwritten that can't be read | v2 gate; E.6 stop on newer record; no sync while unreadable | HabitStore, HabitSync | `HabitStore.load` / record decode | Status `.updateNeeded` / no sync | Fixture tests (v1, v2, v3-unknown); coordinator test |
| Pending changes survive quit (E.10) | Engine state persisted on every `stateUpdate`; **and at every start**, re-queue every habit with a register (or `createdAt`/`deletedAt`) newer than the persisted `lastSentAt` | HabitSync, `SyncPolicy` "started" outcome | `lastSentAt` is written when a send batch finishes with nothing pending | A change made just before a quit or crash, before the engine's `stateUpdate`, is re-queued on the next start | `SyncPolicy` test; manual: change, quit at once, relaunch online |
| Updates to existing records succeed | System fields cache | HabitSync | cache write after each fetch/send | A stale cache gives `serverRecordChanged`, handled by merge with `serverRecord`'s fields, then re-send | Manual: edit the same habit on two Macs |
| Fetched changes never skipped | Merge and save inside the event handler | HabitSync, AppModel | `HabitStore.save` before `handleEvent` returns | A failed save shows E.6 of T-003; the next full fetch (account change, update-needed) recovers | Manual: quit mid-fetch, relaunch |
| A habit is never half-applied (E.9) | One record per habit; payload decoded whole or rejected | HabitSync / HabitCodec | record decode | Record skipped, logged | Codec test with a truncated payload |

| Boundary | Concurrent event | Invariant | Linearization point | Recovery |
| -------- | ---------------- | --------- | ------------------- | -------- |
| Engine callback → main actor | User checks off while a fetch is merging | Both changes kept | Each `AppModel` mutation runs on the main actor in turn; merge is register-wise | The later local change is queued for sending as usual |
| `nextRecordZoneChangeBatch` reads habits | User edits during the batch | Sent payload is a consistent snapshot of one habit | Snapshot taken in one main-actor hop | The edit re-queues the habit; the next batch carries it |
| Remote change while the form is open | Rename arrives during typing | The field being edited stays; others update | `applyRemote` on main | Next keystroke applies only its field (B.11) |
| Remote delete while the form is open | | Form closes | `applyRemote` | List shown |
| Day changes during a merge | `today` moves | B.8a uses one `today` | `mergeFirstSync` takes `today` as a parameter | |

### Red Flags Audit

| Red flag | Present? | If present, why acceptable |
| -------- | -------- | -------------------------- |
| Shallow module | No | HabitSync's surface is `start`, `changed(ids)`, `fetchSoon()`; merging is one call per habit |
| Information leakage | No | The record payload is the HabitCodec format, owned by HabitCalKit; CloudKit types never leave HabitSync |
| Temporal decomposition | No | One codec for file and record; one merge for fetch and conflict |
| Pass-through method | No | |
| Dates as instants | Deliberate | `changedAt` and `createdAt` are instants because "later" is a moment, not a day (B.10); calendar days stay `Day` |
| Rules in the app target | No | All merge, due, and label rules are in HabitCalKit; HabitSync only translates events |
| A second writer | Checked | `sync-state.json` is a different file; habits.json is still written only by `HabitStore` |
| Off-main UI state | Guarded | Concurrency table |

## 7. Interface Contract

| Interface | Inputs | Output | Errors | Async? |
| --------- | ------ | ------ | ------ | ------ |
| `Habits.toggle/add/rename/setNote/setDays/delete(…, now:)` | IDs, values, `today`, `now` | mutated `Habits` | none (invalid input ignored, as today) | no; `Sendable` value type |
| `Habits.replaceAll(with:now:)` | habits from a file | | | no |
| `Habits.applyFormEdit(_:from:to:todayDoneAtOpen:today:now:)` | old and new draft | | | no |
| `Habits.all` (shown) / `Habits.records` (stored) | | | | no |
| `SyncPolicy.decide(_ outcome:, state:) -> SyncDecision` | engine outcome | actions + `SyncStatus` | | no |
| `Habits.merge(_: [Habit], importedAt:)` | remote habits | changed IDs | | no |
| `Habits.mergeFirstSync(remote:importedAt:today:)` | | changed IDs, IDs to re-send | | no |
| `HabitCodec.encode(_: Habit) -> Data`, `decode(_: Data, formatVersion:) throws -> Habit` | | | `HabitCodec.Error.newerFormat`, `.invalid` | no |
| `HabitStore.load/save` | | v2 | as today | no |
| `HabitLabels.syncStatus(_:lastSynced:now:)` | `SyncStatus` | title, detail, spoken | | no |
| `AppModel.applyRemote(_:library:)`, `syncStatus` | | | | `@MainActor` |
| `HabitSync.start()`, `changed(_ ids:)`, `fetchSoon()` | | | | `@MainActor`, delegate methods too |
| `CKSyncEngine` + `CKSyncEngineDelegate` (CloudKit, macOS 14+) | | | `CKError` | delegate methods async, off main |
| `NSApplication.registerForRemoteNotifications()` | | | | main |

**Existing API that changes** (slice 1):
- `Habits.update` is replaced by `rename`, `setNote`, `setDays`, and `applyFormEdit`. `Habits.replace` (T-038) is removed, since `applyFormEdit` supersedes it.
- `Habit.checkOffs: Set<Day>` stays, as the computed set of live `done` checks, so `Streaks`, `Consistency`, and `strip` don't change.
- `Habits.all` keeps its meaning (shown habits).
- These tests get rewritten onto the new operations, keeping their names and rules: the `update…` schedule tests, `replacePutsAHabitBackInPlaceAndIgnoresADeletedOne`, and `deletingAHabitRemovesItAndItsHistory` (now: gone from `all`, kept as a record).

## 8. Data Model & Persistence

- habits.json `formatVersion` 1 → **2**.
  - Per habit: `id`, `name {value, changedAt?}`, `note {…}`, `addedOn`, `createdAt`, `deletedAt?`, `schedule [{from, days, changedAt?}]`, `checks [{day, done, changedAt?}]`.
  - Top level: `formatVersion`, `importedAt?`, `habits`.
  - Times are ISO 8601 with milliseconds, UTC.
- **v1 → v2:** loaded in memory. `changedAt` is nil everywhere; `createdAt` = `distantPast` plus the habit's index in milliseconds, so the order holds and is never later than a real time. Fixture tests cover v1 and v2.
- **One version older (v1 HabitCal) reading v2:** unreadable; shows the T-003 E.5 message and never saves over it. Accepted: there's no released v1 build yet (v1 isn't shipped), so no user can downgrade into this.
- **iCloud records:**
  - `Habit {formatVersion: Int, payload: Bytes}` and `Library {formatVersion, importedAt}`.
  - A record whose `formatVersion` is newer than this build knows stops sync (E.6).
  - The record payload carries no settings and no device data.
- **`sync-state.json`:** `{engineState: Data, firstSyncDone: Bool, systemFields: {recordName: Data}, updateNeeded: Bool, lastSynced: Date?, lastSentAt: Date?}`, owned by HabitSync, atomic write. If it's unreadable, it's discarded and the next start counts as a first sync. That's safe because merging loses nothing.

## 9. Capabilities & Security

- **New entitlements:** `com.apple.developer.icloud-container-identifiers` [`iCloud.com.muchfiner.HabitCal`], `com.apple.developer.icloud-services` [`CloudKit`], and `com.apple.developer.aps-environment` (development for Debug, production for Developer ID). The Developer ID build also gets `com.apple.developer.icloud-container-environment` = `Production`. Still no network entitlement (spike Q2; D-007 unchanged).
- **Signing:**
  - Debug: automatic signing with team LZ2695932J, as the spike did. `run.py build` and `uitest` pass `-allowProvisioningUpdates`.
  - Release: Developer ID with a profile for `com.muchfiner.HabitCal` made at developer.apple.com, naming the certificate that expires 2027-02-01 (spike). That's T-005's job.
- **Validation:** payloads from iCloud go through the same decoder and limits as the file (no trusting remote data more than disk). An invalid record is skipped and logged, never applied partly.

## 10. macOS Versions and Appearance

| Variant | Difference from baseline | Verified how |
| ------- | ------------------------ | ------------ |
| Later macOS | None expected; `CKSyncEngine` is macOS 14+, baseline is 15 | Run on the customer's macOS 27 |
| Intel | None | Universal build |
| Dark mode, Increase Contrast | Status icon is a template image | Settings screenshot, both modes |
| VoiceOver | Status line read as one element (E.11) | Manual VoiceOver check |

## 11. Alternatives / Reuse / Proportionality

| Checked | Stdlib / native / existing dep / new dep | Covers? | Why not | Ceiling / upgrade path |
| ------- | ---------------------------------------- | ------- | ------- | ---------------------- |
| `CKSyncEngine` | Native (CloudKit) | Yes: scheduling, push, retries, account changes, state | Chosen | |
| Hand-rolled `CKFetchRecordZoneChangesOperation` + subscriptions | Native | Yes | Re-implements what the engine does: change tokens, retries, push handling | |
| `NSPersistentCloudKitContainer` (Core Data) | Native | Partly | D-006 rejected Core Data; its merge policies are per-object, not per-field/per-day, so B.21 and the delete/import rows can't be expressed | |
| SwiftData + CloudKit | Native | Partly | Same merge-policy limit; no unique constraints with CloudKit; D-006 | |
| Whole-file record (one record holding habits.json) | Native | No | Any two edits on different habits conflict; merging means merging the whole file on every conflict | |
| One record per check-off | Native | Yes | Thousands of records per user and a schema with relations; one record per habit stays far under CloudKit's 1 MB record limit (≈40 bytes a day, ~70 KB for 5 years) | Split a habit's checks into yearly records if one ever nears 1 MB |

| Rare case | Cost to support | Requirement change that deletes it | Recommend |
| --------- | --------------- | ---------------------------------- | --------- |
| Clock far wrong on one Mac | Hybrid logical clocks | Spec accepts it (Assumptions) | Accept |
| Deleted-habit records pile up | GC needs every Mac to confirm | Non-goal | Accept |
| A newer HabitCal on another Mac | One version check per record | None; cheap | Keep |

## 12. Implementation Slicing Strategy

More than two slices, so st-slice writes the slicing plan. Proposed order:

1. **Mergeable model and v2 format, no CloudKit.** In HabitCalKit: registers, stamping operations, existence, due rule (B.21), `merge`, `mergeFirstSync`, order, `HabitCodec`, HabitStore v2 with the v1 migration. In AppModel: the `now` clock and field-level form edits (B.11). Ships invisibly, and the app behaves exactly as today. Demo: unit tests of every conflict row; the app works on a v1 file and writes v2.
2. **HabitSync.** Entitlements and team signing, `CKSyncEngine`, records, first sync, conflicts, zone reset, account changes, `sync-state.json`, the fetch fallback, and the Settings status line. Demo: manual checks with the CloudKit Console, then a second Mac, or a second macOS user account signed into the same Apple Account.
3. **Import everywhere.** Wire `replaceAll` and the confirmation wording (B.13, B.14) into T-035's import once its code exists. If T-035 isn't built yet, this slice waits for it; nothing else depends on it.

## 13. Testing Strategy

| Test | Kind | Spec rules proved | Regression prevented |
| ---- | ---- | ----------------- | -------------------- |
| `checkAndUncheckSameDayLaterWins`, `editsToDifferentDaysBothKept`, `renameAndNoteOnTwoMacsBothSurvive`, `laterScheduleChangeWinsForItsDays`, `deleteBeatsLaterCheckOffOrEdit`, `addsOnBothMacsBothKept`, `checkOffOnDayAnotherMacUnscheduledStaysDueAndDone` | unit | conflict table, B.10, B.21, E.8 | Lost check-offs, resurrected habits |
| `importReplacesEarlierChangesAndHabits`, `changesAfterImportApplyOnTop`, `importRevivesADeletedHabit` | unit | import rows, B.13, B.15 | A restore undone from another Mac |
| `mergeIsOrderIndependent` (random edits merged in every order) | unit | B.1 (same result everywhere) | Macs disagreeing forever |
| `firstSyncKeepsEveryHabitAndCheckOff`, `firstSyncMergesSameIdAndSameName`, `firstSyncPastDaysDueOnlyIfDueInBoth`, `firstSyncWithoutTimesUsesMostRecentCheckOff`, `mergedHabitKeepsEarlierAddedDate`, `mergedOrderByDateAddedRemoteFirst` | unit | B.7, B.8, B.8a, B.8b, B.9, B.12 | History split or dropped |
| `version1FixtureLoads` (kept), `version1MigratesKeepingOrder`, `version2FixtureLoads`, `savedV2LoadsBackUnchanged`, `newerFormatIsNeverOverwritten` (kept, with a v3 fixture) | integration (real disk) | B.16, B.18 | Data loss on upgrade/downgrade |
| `codecRejectsTruncatedOrNewerPayload` | unit | E.6, E.9 | Half-applied habits |
| `syncStatusLabels` | unit | §5 table, E.11 | |
| `formEditChangesOnlyTheTouchedField`, `formEditRestoresTodayWhenItsDayComesBack` (kit: a remote rename merged, then a note edit) | unit | B.11, T-038 | The form overwriting remote changes |
| `syncPolicy…` one per outcome: conflict merges and re-queues, zone deleted resets and re-queues all, quota → full, network → waiting, newer format → update needed and flag, sign-in/switch reset and first sync, sign-out → off, fetch finished sets first sync done | unit | E.2–E.6, E.9, B.7 | Wrong reaction to a CloudKit event |
| `firstSyncNeverPairsWithADeletedHabit`, `tiesBreakTheSameWayEverywhere`, `v1HabitsStayVisibleAndEditableAfterMigration`, `deletedHabitsNeverInAll` | unit | B.7, B.10, B.12, B.18 | Pass 1 findings 2, 3, 7, 10 |
| `firstSyncPairKeepsTimestampedCheckOffsOlderThanTheOtherCopy`, `firstSyncMergedHabitHasDaysToday`, `syncPolicyHoldsSendsUntilFirstSyncDone`, `syncPolicyRequeuesUnsentChangesAtStart` | unit | B.7, B.8a, B.21, E.10 | Pass 2 findings 1, 3, 4, 5 |
| Existing habit/form UI tests, plus `testSettingsShowsSyncStatus` with `-HabitCalSyncStatus` | UI | B.6, UI section, E.11 | |
| Manual, CloudKit Console: edit a record in Development → shows within 1 minute; delete the zone → resent | manual (real boundary; CloudKit can't run under `swift test`, which is unsigned) | B.2, B.3, B.4, E.4 | Push/fallback broken |
| Manual, two Macs (or two macOS users on one Apple Account): check off, edit the same habit on both (system fields cache), edit offline on both, delete vs edit, first sync with habits on both, quit mid-fetch and relaunch | manual (real boundary) | B.1, B.5, B.7, B.9, conflict table end to end, E.9, E.10 | Engine wiring broken |
| Manual: iCloud full / signed out | manual; accepted risk where not runnable (spike Q3) | E.3, E.5 | |
| `testEscStillClosesAfterTheFocusedStripLeavesTheList` (kept) | UI | B.4 with focus | FM-006 |

Every spec rule appears above. B.14 (the confirmation wording) is tested with T-035's confirmation tests in slice 3. B.19–B.20 are covered by the entitlements review and by not syncing settings.

## 14. Rollout

Direct ship, no flag: v1 isn't released, so no user has v1 data or a v1 build. Signing changes as in §9. For release (T-005): deploy the `Habit` and `Library` record types to production in the CloudKit Console, never the spike's `SpikeHabit`, and sign with the Developer ID profile.

## 15. Reviewer Feedback

| \#  | Finding | Severity | Cost to accept | Decision | Rationale | Next step | Arch? | Source |
| --- | ------- | -------- | -------------- | -------- | --------- | --------- | ----- | ------ |
| 1 | No record system fields kept: every update conflicts forever | BLOCKER | No edit after the first send syncs | ACCEPT | CKSyncEngine saves with ifServerRecordUnchanged | Cache in sync-state.json (§6, §8) | Yes | Pass 1 |
| 2 | v1 data hidden by the ignore rule; v1 createdAt in the future; replaceAll stamping unstated | MAJOR | Existing habits look empty after upgrade | ACCEPT | | Ignore rule non-nil only; createdAt = distantPast + index; replaceAll stamps at now | Yes | Pass 1 |
| 3 | First-sync name pairing with a tombstone deletes a live habit | MAJOR | B.7 data loss | ACCEPT | | Pair shown habits only; no old-account tombstones on switch | | Pass 1 |
| 4 | Holding batches until fetch completes loses them past the saved token | MAJOR | Habits never appear | ACCEPT | | Merge and save per batch; flag on didFetchChanges | | Pass 1 |
| 5 | AppModel and coordinator tests have no target; no CloudKit stand-in | MAJOR | B.11, E.2–E.6 untested | ACCEPT | | applyFormEdit and SyncPolicy in the kit, unit-tested | | Pass 1 |
| 6 | "Came from iCloud first" order differs per Mac | MINOR | Order differs | ACCEPT | | Order by addedOn, createdAt, id; spec B.12 narrowed | Spec | Pass 1 |
| 7 | LWW ties undefined | MINOR | Rare permanent disagreement | ACCEPT | | Fixed tiebreak | | Pass 1 |
| 8 | Records skipped under E.6 never arrive after updating | MINOR | Stale habits | ACCEPT | | Persisted update-needed flag → full refetch | | Pass 1 |
| 9 | E.10 fallback relies on unpersisted lastSynced; redundant account name | MINOR | E.10 unproven | ACCEPT | | Persist lastSynced; drop account name | | Pass 1 |
| 10 | Tombstones would show in the leaderboard and list | MINOR | Deleted habits visible | ACCEPT | | all = shown, records = stored | Yes | Pass 1 |
| 11 | Lasting Changes missing several items | MINOR | Later changes re-derive or break them | ACCEPT | | Added to §16 | | Pass 1 |
| 12 | First sync hides check-offs: merged pair took the later createdAt | BLOCKER | Silent history loss at first sync | ACCEPT | | Pair takes the earlier createdAt; older registers raised to it | Yes | Pass 2 |
| 13 | First sync against a remote import: the import row hides a joining Mac's habits; B.7 keeps them | QUESTION | A Mac joining after a restore shows none of its habits | ASK CUSTOMER | Spec conflict | Recommend B.7 wins (clamp to importedAt) | Spec | Pass 2 |
| 14 | A local habit name-paired after being sent leaves a duplicate record | MAJOR | Duplicates on other Macs | ACCEPT | | No sends until first sync done | | Pass 2 |
| 15 | E.10 fallback only on a write failure | MAJOR | Lost change after a quick quit | ACCEPT | | Re-queue at every start against lastSentAt | | Pass 2 |
| 16 | B.8a can leave no days today | MINOR | Habit hidden; form refuses edits | ACCEPT | | Entry at today with the winner's days | | Pass 2 |
| 17 | Lasting Changes and changed existing API unstated | MINOR | Merge invariant lost later; bigger slice 1 | ACCEPT | | §6 "Existing API that changes", §16 rows | Yes | Pass 2 |

## 16. Lasting Changes

| Change | Goes to |
| ------ | ------- |
| HabitSync component, CloudKit boundary, `sync-state.json`, record types, fetch fallback | ARCHITECTURE.md (Components, Boundaries, State and Persistence) |
| Mergeable model: registers, existence rule, due includes live check-offs, merge and first-sync merge | ARCHITECTURE.md, "State and Persistence" |
| habits.json v2 and the iCloud record format (shared HabitCodec) | CONTRACTS.md, "Saved habit data" (v2) and a new "Synced habit records" |
| Every habit change takes `now` and goes through `persist()`, which notifies sync; only HabitSync imports CloudKit | CONVENTIONS.md |
| Tests never sync: sync is off with `-HabitCalDataDir`; `-HabitCalSyncStatus` shows a status | TESTING.md |
| Release steps: deploy schema to production, Developer ID profile with iCloud | T-005 (TASKS detail) and TESTING.md manual tests |
| Rejected: Core Data / SwiftData CloudKit mirroring, whole-file record, per-check-off records | DECISIONS.md (new entry refining D-010) |
| Trap: a new CloudKit container takes ~1 minute before it answers (CKError 5) | COMMON-FAILURE-MODES.md |
| Trap: saving a freshly built `CKRecord` for an existing ID always conflicts; keep and reuse the record system fields | COMMON-FAILURE-MODES.md |
| Trap: CKSyncEngine moves its change token after each batch; merge and save before `handleEvent` returns | COMMON-FAILURE-MODES.md, CONVENTIONS.md |
| Deleted habits stay as records forever; HabitCal never deletes a CloudKit record | ARCHITECTURE.md, CONTRACTS.md "Synced habit records" |
| `Habits.all` is shown habits only; `records` is storage | ARCHITECTURE.md |
| Debug syncs to CloudKit Development, Release to Production; they never see each other | TESTING.md |
| The Release config carries no iCloud entitlements until T-005's Developer ID profile exists (an ad-hoc build with them won't launch) | T-005 detail; ARCHITECTURE.md Open Questions |
| Rejected: hybrid logical clocks (clock skew accepted), hand-rolled CloudKit operations | DECISIONS.md (with the entry above) |
| Form edits are field-level through `Habits.applyFormEdit`, replacing T-038's whole-habit snapshot (ARCHITECTURE.md line on schedules and the form) | ARCHITECTURE.md |
| Sync decisions live in `SyncPolicy` (HabitCalKit); HabitSync only translates CloudKit | ARCHITECTURE.md, CONVENTIONS.md |
| Practice: every synced field is a register with a change time and a tie-break; adding or changing one bumps the record and file `formatVersion` | CONVENTIONS.md |
| No sends until the first sync finishes; unsent changes re-queued at every start | ARCHITECTURE.md |
