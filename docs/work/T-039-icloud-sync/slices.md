---
name: iCloud sync slicing plan
task: T-039
design doc: docs/work/T-039-icloud-sync/design.md
design doc version/commit: d138e8c
date created: 2026-11-01
last updated: 2026-11-01
status: Approved
---

# Slicing Plan: iCloud Sync Across Macs

## 0. Sliceability Gate

- Design conclusion: "More than two slices, so st-slice writes the slicing plan. Proposed order: 1. Mergeable model and v2 format, no CloudKit. … 2. HabitSync. … 3. Import everywhere. … If T-035 isn't built yet, this slice waits for it; nothing else depends on it."
- Design change required to slice: none. One wording fix: §12's slice 1 still says "field-level form edits (B.11)". §6 now has `applyFormEdit` writing the form's details whole (customer, 2026-11-01). This plan follows §6.

## 1. Rejected Alternative

The design's three slices as written, with signing, entitlements, the engine, conflicts, account handling, and the status line all in one slice 2. Rejected because it mixes two unrelated risks:
- Switching the app to team signing with iCloud entitlements can break `run.py`, the UI tests, and launching. That's provable in an hour.
- The CKSyncEngine wiring needs a second Mac or the CloudKit Console to prove.

Splitting them means a signing problem is found before any sync code exists, and the sync slice starts from an app already known to launch with iCloud.

Also rejected: a kit-only slice for `SyncPolicy`. It has no demo of its own, and its rules are only meaningful next to the code that feeds it events, so it goes with the sync engine (slice 3).

## 2. Slices

### Slice 1: Mergeable habits and habits.json v2, no iCloud

| Field | Value |
| --- | --- |
| Status | Done (b0428b7); UI tests and the on-screen check of real v1 data outstanding, customer chose to test later |
| Scope | **HabitCalKit:** `details` and per-day `checks` registers; `createdAt`, `deletedAt`; `all` (shown) vs `records` (stored); due includes live check-offs (B.21); stamping operations `toggle`, `add`, `setDetails`, `delete`, `replaceAll`, `applyFormEdit`; `merge` with the tie rule; `mergeFirstSync` (ID and name pairing, B.8a intersection plus today's entry, B.8b); order (B.12); `HabitCodec`; `HabitStore` v2 with the v1 migration and a v3-unknown gate. **App:** `AppModel` gets an injected `now` clock from `LaunchOptions` and calls the stamping operations; `updateDraft` uses `applyFormEdit`. Existing tests on `update`/`replace`/`delete` are rewritten onto the new operations, keeping their rules (design §6 "Existing API that changes"). |
| Demo criterion | `swift test` green, including a test for every conflict-table row, every first-sync rule, order independence, and fixture loads of v1 and v2. The app runs on the customer's existing v1 file and shows every habit, streak, and strip exactly as before. After one check-off, `habits.json` is v2. The habits, form, and day-selection UI tests pass on the customer's screen. |
| Dependencies | Current main (T-038's `formStart`/`Habits.replace`, T-036's due-only list). |
| Explicitly deferred | Everything CloudKit; signing; the Settings status line; `SyncPolicy` (slice 3); wiring `replaceAll` to an import UI (slice 4). |
| Invalidation risk | **Format change:** habits.json v2 isn't revertible. A build from before this slice treats a v2 file as unreadable and never overwrites it (D-004). There's no released build, so the risk is only to the customer's own data during development. Debug (`com.muchfiner.HabitCal.debug`) and Release (`com.muchfiner.HabitCal`) have separate containers, so an installed Release copy keeps its own v1 file. Before the first v2 write, `run.py` doesn't back up the file, so **copy `habits.json` aside before running this slice's build** (noted in the commit). **Due rule:** checked-off days count as due, which could change a streak if old data has check-offs on unscheduled days. v1 never allowed that, but the clock-moved-backward case (T-003 E.7) is checked by a test on the v1 fixture. **Falsified if** any existing Streaks, Consistency, or strip test changes its expected value. |
| Size justification | One outcome: habits carry what merging needs, saved and loaded, with no visible change. Splitting the format from the model would leave a model nothing saves. |
| Test gate | Failing tests first at design §13's kit rows (`swift test --package-path HabitCalKit`), then implement; then the habits, form, and day-selection XCUITests. |

### Slice 2: Signed with iCloud, and Settings shows the real account status

| Field | Value |
| --- | --- |
| Status | Done (see Checkpoint Log); UI tests and a look at the status line outstanding |
| Scope | An entitlements file (iCloud container, CloudKit, `aps-environment`). Debug signs automatically with team LZ2695932J. Release keeps ad-hoc signing **without** the iCloud entitlements until T-005's Developer ID profile exists (design §16). `run.py build`/`run`/`uitest` pass `-allowProvisioningUpdates`. A minimal `HabitSync` that, when not disabled (`-HabitCalDataDir`, unreadable data), asks CloudKit for the account status at launch and on `.CKAccountChanged`, and sets `AppModel.syncStatus` to off / available ("Not synced yet") / error. **Sync is also off in any build without the CloudKit entitlement** (Release until T-005): such a process traps on touching `CKContainer`, so HabitSync checks the entitlement first and never creates a container without it (status "iCloud is off"). `HabitLabels.syncStatus` covers every state in the spec's table. `SyncStatusRow` sits at the top of Settings' DATA section (T-035's DATA section if present, otherwise a DATA heading with just this row). There's a Debug-only `-HabitCalSyncStatus <state>` to show any state. |
| Demo criterion | `./run.py run` builds team-signed, and the app launches. Settings shows the real iCloud status for the customer's account. **A Release build (no iCloud entitlement) launches and shows "iCloud is off".** The full UI suite still passes (tests never sync). `testSettingsShowsSyncStatus` passes for each state. VoiceOver reads the line as one element. |
| Dependencies | Slice 1 isn't consumed: this slice is independent of the model and could run first. It goes second so slice 3 starts from a v2 model and a signed app. |
| Explicitly deferred | Records, the engine, merging, Sync Now (slice 3). The "Synced with iCloud · time" state only appears in slice 3. |
| Invalidation risk | **Signing:** automatic Debug signing needs Xcode's account signed in. On a Mac without it, `run.py` fails to build. That's accepted and documented in TESTING.md. **UI tests:** the test runner may need its own provisioning. **Falsified if** the UI test target can't be signed automatically; then sign the runner ad hoc and give only the app the profile. |
| Size justification | One outcome: the shipped app is allowed to use iCloud and says so truthfully. It isolates the signing risk from the sync logic. |
| Test gate | `syncStatusLabels` (kit) and `testSettingsShowsSyncStatus` (UI) first, then implement. Signing itself is proved by building and launching (manual, recorded in the commit). |

### Slice 3: Habits sync through CKSyncEngine

| Field | Value |
| --- | --- |
| Status | In Progress: code committed (10b3025) and the upload/download round trip verified on the customer's account; demo checks (2)–(5) and UI tests outstanding, so not Done (finding 2) |
| Scope | **`SyncPolicy` in HabitCalKit, for the outcomes this slice handles:** fetched records, conflict, fetch finished, first sync, sends held then sent, local change. **HabitSync:** `CKSyncEngine` on the private database with zone `Habits`; the `Habit` record (`formatVersion`, `payload` = `HabitCodec`); the system fields cache; `sync-state.json` (engine state, first-sync flag, cache, `lastSynced`, `lastSentAt`); sends held until the first sync finishes, then sent at once; merge and save per batch inside the handler; conflict merge and re-send; `fetchSoon()` from DayWatcher's wake and 60 s timer; `registerForRemoteNotifications`. **Sync Now (B.22):** the button added to slice 2's `SyncStatusRow`. **App:** `AppModel.applyRemote`; `persist()` → `sync.changed(ids)`; a form on a habit deleted remotely closes. |
| Demo criterion | Manual, against CloudKit's Development environment: (1) a check-off appears in the CloudKit Console; (2) editing a record in the Console shows in HabitCal within a minute, recording whether push or the fallback delivered it; (3) **stale system fields:** edit a habit in the Console, then edit the same habit in HabitCal before it fetches. The change still lands, merged, proving the conflict path; (4) Sync Now shows "Syncing…" then "Synced"; (5) on a second Mac, or a second macOS user signed into the same Apple Account: first sync with habits on both, same-name merge, edits on both, delete vs edit. The `SyncPolicy` tests for these outcomes, `syncNowDisabledWhileOffOrSyncing`, and `testSyncNowShowsSyncingThenResult` pass. |
| Dependencies | Slice 1's `merge`, `mergeFirstSync`, `HabitCodec`, and stamping (consumed directly). Slice 2's signed app, entitlements, entitlement check, `HabitSync` shell, status plumbing, and `SyncStatusRow`. |
| Explicitly deferred | Recovery paths: zone reset, account change, newer-format stop and refetch, quota/network statuses, re-queue at start (slice 4). Import wiring (slice 5). Garbage collection of deleted records (design non-goal). Production schema deployment (T-005). |
| Invalidation risk | **Push:** unproven (design §3). The 60 s fallback covers B.2; the demo records which one delivered it. **Second Mac:** if neither a second Mac nor a second macOS user is available, the slice **stays In Progress**, not Done, because demo (5) is the only proof of first sync (B.7–B.9) and delete vs edit. **Falsified if,** after quitting mid-fetch and relaunching, a Console edit made before the quit never shows locally. That means per-batch save inside the handler isn't enough (design §6). |
| Size justification | One outcome: habits sync between Macs in the normal case. Recovery is split off (slice 4) so a failure here points at the engine, not at a rare path. |
| Test gate | `SyncPolicy` tests for this slice's outcomes, `syncNowDisabledWhileOffOrSyncing` (kit), and `testSyncNowShowsSyncingThenResult` (UI, stand-in status) first; then implement; then the manual checks. The CloudKit boundary has no automated test (design §13: CloudKit can't run in an unsigned test process). |

### Slice 4: Sync recovers from resets, account changes, and errors

| Field | Value |
| --- | --- |
| Status | In Progress: code committed and checked against the customer's account; the manual checks (Console zone delete, change-then-quit, Wi-Fi off) outstanding |
| Scope | `SyncPolicy` outcomes and HabitSync handling for: zone deleted or user data reset → recreate and re-send all (E.4); account sign-in, switch, and sign-out → reset state and cache, first sync again, no old-account deleted records sent (E.2, E.3); a newer-format record → status "Update HabitCal to sync", stop sending, persisted update-needed flag, then a full refetch once updated (E.6); quota and network → "iCloud is full" and "Waiting for iCloud" (E.5, B.5); re-queue of unsent changes at every start against `lastSentAt` (E.10). |
| Demo criterion | The `SyncPolicy` tests for each outcome above pass. Manual: delete the zone in the CloudKit Console, and everything is re-sent; make a change, quit at once, relaunch online, and it reaches the Console; turn Wi-Fi off, and Settings says "Waiting for iCloud", then "Synced" after it's back. Sign-out and iCloud full aren't run (spike Q3, accepted risk) and are covered by `SyncPolicy` tests. |
| Dependencies | Slice 3's working engine, state file, and `SyncPolicy`. |
| Explicitly deferred | Import wiring (slice 5). |
| Invalidation risk | **Newer format** can't be produced for real until a v3 exists. It's proved by a `SyncPolicy` test and a hand-edited record in the Console with `formatVersion` 3. **Falsified if** CloudKit reports a deleted zone through an event the design doesn't list. Handle it the same way and record it. |
| Size justification | One outcome: sync heals itself after anything but normal use. Each path is rare, and together they share `SyncPolicy`. |
| Test gate | `SyncPolicy` tests for each outcome first, then implement, then the manual checks. |

### Slice 5: Import replaces habits on every Mac

| Field | Value |
| --- | --- |
| Status | Blocked |
| Blocked | Waits for T-035's import code, which doesn't exist yet. |
| Scope | T-035's import calls `Habits.replaceAll(with:now:)` (slice 1) instead of its own replace. When sync is on, the confirmation says "on all your Macs" (B.14). |
| Demo criterion | Import on Mac A; Mac B shows exactly the file's habits. A habit added on B while offline before the import survives it (spec conflict table). T-035's confirmation tests check both wordings. |
| Dependencies | Slice 1's `replaceAll`; slices 3 and 4's sync; T-035's import UI. |
| Explicitly deferred | Nothing else. |
| Invalidation risk | **Order:** if T-035 is built after slice 4, T-035 should call `replaceAll` from the start, and this slice shrinks to the wording. **Falsified if** T-035's spec changes import to merge instead of replace. |
| Size justification | One small outcome, kept separate only because it depends on another task. |
| Test gate | T-035's confirmation tests for both wordings, sync on and off (UI, with a stand-in status), first. Then implement. Then the manual two-Mac check that the import replaces habits on both Macs, and that a habit added offline on Mac B before the import survives. |

## 3. Review Findings

| # | Finding | Category | Severity | Decision | Slices | Rationale | Next step |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Release builds without the iCloud entitlement would trap on `CKContainer` | SLICING | MAJOR | ACCEPT | 2 | | Entitlement check; Release launch in the demo |
| 2 | Slice 3 could be Done without its two-Mac proof | SLICING | MAJOR | ACCEPT | 3 | | Stays In Progress without it; stale-system-fields Console check added |
| 3 | Slice 3 too big | SLICING | MAJOR | ACCEPT | 3, 4 | | Split: sync (3), recovery (4) |
| 4 | Sync Now tests and the row change missing | SLICING | MINOR | ACCEPT | 3 | | Named |
| 5 | Drift table incomplete | SLICING | MINOR | ACCEPT | 3, 5 | | Added |
| 6 | Unobservable falsifier | SLICING | MINOR | ACCEPT | 3 | | Observable signal named |
| 7 | Installed copy shares the container | SLICING | MINOR | REJECT | 1 | Debug and Release have different bundle IDs and containers (project.pbxproj; ARCHITECTURE.md) | Noted in slice 1 |
| 8 | Slice 4 (now 5) test gate adds nothing | SLICING | MINOR | ACCEPT | 5 | | Wording tests and a two-Mac check named |
| 9 | Should `mergeFirstSync` wait for slice 3? | SLICING | QUESTION | ACCEPT AS IS | 1 | It's pure and fully specified; if slice 3 changes its outputs, its tests change with it (invalidation risk) | None |

## 4. Dependency Graph

```
main ──▶ Slice 1 (model, v2) ──┐
main ──▶ Slice 2 (signing, status) ──┴──▶ Slice 3 (sync) ──▶ Slice 4 (recovery) ──▶ Slice 5 (import everywhere) ◀── T-035
```

Slices 1 and 2 are independent of each other; slice 3 needs both; slice 4 needs slice 3; slice 5 needs slice 4 and T-035.

## 5. Checkpoint Log

### After Slice 1

- Commit: b0428b7
- Affected remaining slices reviewed: 2 (independent of the model: unchanged), 3 (consumes `merge`, `mergeFirstSync`, `HabitCodec`, `MergeResult.toSend`: as planned), 5 (`replaceAll` exists).
- Changed: none.
- Unchanged and why: the kit API matches design §7 except the order key (Design Drift); slice 3's inputs exist as specified.
- New conflicts: none. Outstanding from slice 1's demo: the habits, form, and day-selection UI tests, and a look at the customer's real data after the v1 → v2 change.

### After Slice 2

- Commit: the slice 2 commit after b6302be ("T-039 slice 2: signed with iCloud…")
- Affected remaining slices reviewed: 3 (consumes the HabitSync shell, `SyncStatus`, `SyncStatusRow`, entitlements: as planned; `allowsSyncNow` already exists and is tested, so slice 3's `syncNowDisabledWhileOffOrSyncing` is covered by `syncNowOnlyWhenICloudIsAvailableAndIdle`), 4 and 5 unchanged.
- Changed: none.
- Unchanged and why: the shell's account-status mapping is the "off/waiting" part of slice 4's statuses; slice 4 still owns sign-in/switch handling of engine state.
- New conflicts: the Xcode account sign-in lapsed once during this slice ("No Accounts"); signing in again fixed it. Building now depends on it. Outstanding: the UI tests and a look at the line.

### After Slice 3 (code; demo outstanding)

- Commit: 10b3025
- Affected remaining slices reviewed: 4 (recovery builds on HabitSync's event handling, `SyncState`, and `handleFailedSaves`: as planned; `zoneNotFound` and `unknownItem` are already handled in slice 3 because the first run needs them), 5 unchanged.
- Changed: slice 4 no longer needs to add basic zone-not-found handling, only the user-deleted-zone path and account/newer-format/quota/network handling.
- Unchanged and why: the engine's event shape matched the design.
- New conflicts: CKSyncEngine's background task scheduling fails in the sandbox ("BUG IN CLOUDKIT"), so automatic syncing relies on the 60 s fetch and pushes. Engine calls must start detached from callbacks (recorded for COMMON-FAILURE-MODES at close).

### After Slice 4 (code; manual checks outstanding)

- Commit: the slice 4 commit after e6506ef ("T-039 slice 4: sync recovers…")
- Affected remaining slices reviewed: 5 (still blocked on T-035; `replaceAll` and sync are in place).
- Changed: none.
- Unchanged and why: slice 5 needs only T-035's import UI and the confirmation wording.
- New conflicts: adding a field to `SyncState` makes an older `sync-state.json` undecodable; it's dropped and the next start re-runs a first sync, which loses nothing (seen here). Accepted; noted for ARCHITECTURE at close.

## 6. Design Drift

| Change | Affected slices | Reevaluation |
| --- | --- | --- |
| §12 slice 1 says "field-level form edits"; §6 (customer, 2026-11-01) writes details whole via `applyFormEdit` | 1 | Plan follows §6; §12 wording to be corrected at close |
| Design §6 puts the fetch fallback on `DayWatcher`'s wake and timer; HabitSync has its own wake observer and 60 s timer | 3 | Keeps sync triggers inside HabitSync; DayWatcher stays the owner of "today" only |
| First sync with an empty iCloud: §6 queued local habits only through fetched batches; nothing arrives, so the first-sync merge runs once more at `didFetchChanges` | 3 | Found running it; covered by the round-trip check |
| §3 calls the push check "slice 2's manual check"; §13 tests B.14 "in slice 3". The plan has five slices: push is slice 3, B.14 slice 5 | 3, 5 | Plan numbering governs |
| Design §6 orders by `addedOn`, then `createdAt`, then ID. Implementation orders by `createdAt`, then ID: v1 lists aren't sorted by `addedOn` (the UI tests' seed lists Push-ups, added Oct 1, before Run, added Sep 1), so `addedOn` first would reorder them. `add` keeps a new habit last by stamping `createdAt` just after the latest | 1 | Same guarantee (one fixed order on every Mac, v1 order kept); found during slice 1 |
