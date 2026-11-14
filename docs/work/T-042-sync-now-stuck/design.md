---
task: T-042
rigor: Simple
status: Approved
date created: 2026-11-13
---

# Tech Design: Sync Now sticks on "Syncing…"

## Summary

Symptom: after a save iCloud refused and won't retry itself (it lands in `failedSends`, `HabitSync.handleFailedSaves` default branch), Sync Now shows "Syncing…" for good, with its button disabled, until a relaunch. Cause, from source: `syncNow()` doesn't queue `failedSends` again, so the refused change isn't sent; when the fetch and send succeed, `markSynced()` returns early on a non-empty `failedSends` without replacing `.syncing`. The 60 s fetch ends in `markSynced()` too, so nothing clears it. Only a relaunch re-queues failed sends (`start()`). Second symptom: with an unreadable habits file sync never starts (E.1), yet Settings offers a Sync Now that does nothing (`syncNow()` returns on a nil engine). Reproduced by a failing unit test of the status rule.

## Approach

- `SyncPolicy.swift`: new `statusWhenSyncFinished(current:updateNeeded:hasFailedSends:now:) -> SyncStatus`. A newer format wins (`.updateNeeded`); with failed sends, a failure status already shown (`.waiting`, `.full`, `.error`) stays, and anything else (`.syncing`, `.synced`, `.notSyncedYet`) becomes `.error("Some changes haven't reached iCloud yet.")`, the text `refreshAccountStatus` already uses; otherwise `.synced(now)`.
- `HabitSync.swift`: `markSynced()` sets the status from that rule (still skipping while Sync Now's minimum time runs). `syncNow()` queues `failedSends` again before fetching, as `start()` does, so Sync Now retries what was refused.
- `SyncStatusRow.swift`: no Sync Now while the habits can't be read (`model.canAddHabits` false), since sync never started.

## Test Points

| Test (named for the behavior it proves) | Kind | Spec rules proved |
| --- | --- | --- |
| `syncThatFinishesWithRefusedChangesSaysSoInsteadOfSyncing` | unit | T-039 B.5, B.22 |
| `syncThatFinishesKeepsAFailureAlreadyShown` | unit | T-039 B.5, E.5 |
| `syncThatFinishesCleanlyIsSyncedAndANewerFormatWins` | unit | T-039 B.22, E.6 |
| Sync Now retries a refused change (CloudKit Console: make a save fail, then Sync Now) | manual | B.22 |

## Risks

- FM-004 (UI state off the main actor): `markSynced` runs on the main actor, as before; no change.

## Lasting Changes

None. The rule lives in `SyncPolicy` and its tests.

## Reviewer Feedback

| # | Finding | Source | Severity | Decision | Why |
| --- | --- | --- | --- | --- | --- |
| 1 | A sign-out during Sync Now ended on "Synced": the rule ignored `.off` | Pass 1 (diff) | MINOR | ACCEPT | Off now stays off; `syncThatFinishesAfterASignOutStaysOff` |
| 2 | A failed save that can't be rebuilt (habit gone, encode fails) stayed in `failedSends`, so every Sync Now ended in the error | Pass 1 (diff) | MINOR | ACCEPT | Dropped saves leave `failedSends` too |

Diff review verdict: CONCERNS (2 minor, both fixed). The wiring (`syncNow` re-queues, `markSynced` uses the rule) is proved only by the manual check above, which runs in the customer's testing pass before the close.
