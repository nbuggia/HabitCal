---
name: iCloud sync across Macs
task: T-039
status: Approved
last updated: 2026-11-01
---

# Spec: iCloud Sync Across Macs

## 1. Summary

HabitCal keeps a person's habits the same on every Mac signed into their iCloud, with no sign-in and nothing to set up. Check off a habit on the laptop and it's done on the desktop, too. The only thing they see of sync is one status line in Settings. HabitCal keeps working fully on its own when iCloud isn't available (D-010).

## 2. Users

- **For:** someone who uses HabitCal on two or more Macs signed into the same Apple Account, such as a work laptop and a home desktop.
- **Core value:** a habit checked off, added, edited, or deleted on one Mac shows the same on the others, without them doing anything, and nothing they did on either Mac is lost.
- **Not for:** sharing habits between different people, or using HabitCal on an iPhone or iPad (PRD Not Doing).

## 3. Not Doing

- A sync switch in HabitCal. Sync follows the Mac's iCloud sign-in; there's nothing to turn on (customer, 2026-11-01: status only).
- A sign-in, account, or server of our own (D-010).
- Syncing settings: week start and launch at login stay per Mac. Each Mac can reasonably differ, and launch at login depends on where the app is installed.
- Showing sync anywhere but Settings: no menu bar badge, banner, or alert (customer, 2026-11-01).
- Asking the user to resolve conflicts. HabitCal resolves every conflict itself by the rules in section 7, so sync stays invisible.
- History of what synced, or undoing a sync.

## 4. Current Behavior

- Habits live in one file on the Mac, in a versioned format; nothing leaves the Mac — CONTRACTS.md, "Saved habit data"; D-004 (now D-010).
- Every change is saved at once; a failed save shows "Couldn't save — your last change may be lost" — T-003 B.18, E.6.
- A saved file HabitCal can't read (including a newer format) is never overwritten; the list shows "HabitCal couldn't read your habits", and Add and the leaderboard are disabled — T-003 E.5; tests `newerFormatIsNeverOverwritten`, `unreadableFileIsNeverOverwritten`.
- Edits in the Edit form save as they're made; a new habit waits for Add — T-038 (uncommitted at the time of writing). Each edit is applied to a copy of all habits taken when the form opened (`AppModel`), so as built it would undo changes arriving from another Mac while the form is open; B.11 rules that out.
- Export and import are specified but not built: import replaces every habit after a confirmation — T-035 spec.
- The PRD now allows habit data to leave the Mac for the person's own iCloud only — PRD Done Means; D-010. No network entitlement — D-007; the spike showed CloudKit needs none.

## 5. UI

- Settings, DATA section (T-035's), first row: an iCloud status line with a small icon, above Export and Import. One line of text, with a second, smaller line only where shown below.

| State | Line | Second line |
| --- | --- | --- |
| Up to date | Synced with iCloud | Last synced 9:41 AM (or a date) |
| Sending or receiving changes | Syncing with iCloud… | |
| Not signed into iCloud, or iCloud unavailable to HabitCal | iCloud is off | Habits stay on this Mac. Sign into iCloud in System Settings to sync your Macs. |
| Offline or iCloud unreachable | Waiting for iCloud | Changes will sync when this Mac is back online. |
| iCloud storage full | iCloud is full | Changes stay on this Mac until there's room. |
| Another Mac's HabitCal is newer (E.6) | Update HabitCal to sync | Another Mac has a newer version. Habits on this Mac still work. |
| Any other error | Can't sync with iCloud | macOS's reason, in plain words |

- The line updates while Settings is open. It's text, not a control, read by VoiceOver as one element: "iCloud: Synced with iCloud, last synced 9:41 AM".
- The import confirmation (T-035) says "…on all your Macs" when sync is on (B.14).

## 6. Use Cases

| Use case | Journey | How to verify |
| --- | --- | --- |
| UC-1 Check off on one Mac, see it on another | Check off on the laptop; on the desktop the habit shows done, the strip and streak updated. | Manual test on two Macs; unit tests of merging |
| UC-2 Start syncing two Macs that both have habits | Install HabitCal on a second Mac that already had its own habits, or sign into iCloud: both sets merge, nothing lost. | Unit tests of the first merge; manual test |
| UC-3 Work offline | Check off and edit on a Mac with no network; it syncs when back online, merging with what changed elsewhere. | Unit tests of every row of the conflict table and of B.11 with the form open; manual test |
| UC-4 Know whether sync works | Open Settings and read the iCloud line. | UI test with stand-in states; manual test |
| UC-5 Restore everywhere | Import a file on one Mac; every Mac shows the imported habits. | Unit test; manual test |

## 7. Behavior

### New: syncing

B.1 WHILE the Mac is signed into iCloud and online THE SYSTEM SHALL send every change to the user's private iCloud database and apply changes from their other Macs, without any action from the user.

B.2 WHEN a change is made on one Mac and both Macs are online with HabitCal running THE SYSTEM SHALL show it on the other within one minute.

B.3 WHEN HabitCal launches, or the Mac wakes or comes back online THE SYSTEM SHALL fetch changes made elsewhere and send changes made here meanwhile.

B.4 WHEN changes arrive while the popover is open THE SYSTEM SHALL update the list, strips, streaks, and leaderboard in place, without closing or resetting the popover.

B.5 WHILE iCloud isn't available (not signed in, restricted, offline, full, or any error) THE SYSTEM SHALL work exactly as it does without sync, keep every change on the Mac, and send it once iCloud is available again.

B.6 THE SYSTEM SHALL never ask the user anything about sync, and show its state only in Settings (section 5).

### New: merging (first sync)

B.7 WHEN a Mac starts syncing with habits of its own and iCloud already holds habits THE SYSTEM SHALL merge them: every habit from either side is kept, with all its check-offs. Why: the customer chose merge (2026-11-01).

B.8 WHEN the same habit is on both sides at the first sync (the same habit, e.g. both Macs imported one export) THE SYSTEM SHALL keep one copy with: the check-offs of both; the earlier date added; the name, note, and current schedule from whichever side changed them last; and for past days, the merged history of B.8a.

B.8a WHEN two copies of a habit are merged THE SYSTEM SHALL treat a past day as due only if it was due in both copies' histories, or has a check-off from either. Why: it never drops a check-off (B.21) and never turns a day into a missed one that neither Mac showed as missed, so no streak gets shorter by merging.

B.8b WHEN a side's habits were saved before sync existed, so carry no change times THE SYSTEM SHALL treat the copy with the most recent check-off as changed last; with no check-offs on either, the copy already in iCloud.

B.9 WHEN two different habits with the same name (ignoring case and spaces at the ends) meet at the first sync THE SYSTEM SHALL merge them as in B.8. Why: the customer chose merge (2026-11-01). The common case is setting HabitCal up by hand on each Mac, and two "Push-ups" would split one habit's history in two. Accepted: two genuinely different habits that share a name are combined, and that can't be undone.

### New: conflicts (suggested by the agent, approved by the customer 2026-11-01)

Rules are checked per habit and per day, not per file, so unrelated changes on two Macs never conflict.

| Changed on Mac A | Changed on Mac B, before they synced | Result on both |
| --- | --- | --- |
| Checked off day D | Checked off day D | Done |
| Checked off day D | Unchecked day D | Whichever was later wins |
| Checked off day D | Any change to day E, or to another habit | Both kept |
| Renamed, or note changed | Renamed, or note changed | The later change wins, per field: a name change on A and a note change on B both survive |
| Schedule changed | Schedule changed | The later change wins for the days it covers; past days keep the schedule in force then (CONTEXT, "Schedule") |
| Deleted the habit | Checked off, or edited it | Deleted. Why: deleting asks first and says it can't be undone (T-003 B.15); a check-off on another Mac shouldn't bring back a habit someone chose to delete |
| Added a habit | Added a habit | Both kept (B.9 doesn't apply after the first sync) |
| Changed the schedule so day D isn't due | Checked off day D | The check-off stays and day D counts as due and done for that habit (B.21) |
| Imported a file (B.13) | Any change made before the import, or a habit added before it | Replaced by the import: the habit added before it is removed |
| Imported a file (B.13) | A check-off or edit made after the import, to a habit the import kept | Applied on top of the imported habits |
| Imported a file (B.13) | Deleted a habit, before the import | The import brings it back if the file has it |

B.21 THE SYSTEM SHALL never delete a check-off when merging or resolving a conflict. A check-off on a day the merged schedule doesn't include makes that day due and done for that habit; only an uncheck (the later change on that day), a delete, or an import removes one. Why: a check-off records something the person did (review finding 1).

B.10 THE SYSTEM SHALL resolve "later" by when the change was made on its Mac, not when it reached iCloud. Why: a change made offline in the morning shouldn't beat one made online in the afternoon just because it synced last.

B.11 WHEN a habit open in the Edit form is changed on another Mac THE SYSTEM SHALL keep the field the user is editing as they left it, and apply the other changes. An edit in the form changes only the field the user changed (name, note, or days); changes from other Macs to other fields, to other habits, and check-offs arriving while the form is open are kept and shown. WHEN the habit is deleted on another Mac THE SYSTEM SHALL close the form and show the list.

B.12 THE SYSTEM SHALL keep the list in the order habits were added, the same on every Mac. Merged habits are ordered by date added; ties fall in one fixed order, the same on every Mac. The order may change once, at the first merge. (Narrowed in design review: "in iCloud first" isn't known the same way on every Mac.)

### New: import and delete everywhere

B.13 WHEN an import (T-035) goes ahead THE SYSTEM SHALL replace the habits on every Mac syncing with this one, not just this Mac. Why: the customer chose this (2026-11-01); a restore that came back undone from another Mac would look broken.

B.14 WHILE sync is on THE SYSTEM SHALL say so in the import confirmation: "Your N habits on all your Macs (last checked off …) will be replaced by …". Changes T-035's wording.

B.15 WHEN a habit is deleted THE SYSTEM SHALL delete it, with its history, on every Mac.

### Changed

B.16 WHEN HabitCal saves habits THE SYSTEM SHALL also record what's needed to merge them by section 7 (when each change was made, and which habits were deleted). Was: only the habits themselves (CONTRACTS.md, "Saved habit data", format version 1). Why: without it, two Macs' changes can't be merged without losing one.

### Unchanged

B.17 THE SYSTEM SHALL CONTINUE TO save every change on the Mac at once, and work fully offline. Covered by: `savedHabitsLoadBackUnchanged`, and the habits UI tests.

B.18 THE SYSTEM SHALL CONTINUE TO read every earlier saved format, and never write over a file it can't read. Covered by: `version1FixtureLoads`, `newerFormatIsNeverOverwritten`, `unreadableFileIsNeverOverwritten`.

B.19 THE SYSTEM SHALL CONTINUE TO open no network connections of its own; sync goes only to the user's private iCloud database (D-007, D-010). Covered by: the build's entitlements (no network entitlement); review.

B.20 THE SYSTEM SHALL CONTINUE TO keep week start and launch at login per Mac.

## 8. Limits

- Change shown on another Mac: within 1 minute while both are online and HabitCal is running (B.2).
- Nothing synced but habit data: no settings, no identifiers of the Mac or the person beyond what iCloud itself requires.
- Merging never loses a check-off (B.21).

## 9. Edge Cases and Errors

E.1 WHEN the saved habits on this Mac can't be read (T-003 E.5) THE SYSTEM SHALL not sync at all: nothing sent, nothing received, nothing overwritten. Settings shows "Can't sync with iCloud" with "HabitCal couldn't read the habits on this Mac."

E.2 WHEN the Mac signs into a different Apple Account THE SYSTEM SHALL stop syncing with the old account and merge this Mac's habits into the new account's, as a first sync (B.7). Why: the customer chose merge (2026-11-01); one person, one account is the common case.

E.3 WHEN the user signs out of iCloud THE SYSTEM SHALL keep every habit on this Mac and show "iCloud is off".

E.4 WHEN the user deletes HabitCal's data from iCloud (System Settings, Manage storage) THE SYSTEM SHALL treat iCloud as empty and send this Mac's habits again on its next sync. Why: the habits on the Mac are the user's; iCloud is a copy.

E.5 WHEN iCloud is full THE SYSTEM SHALL keep changes on the Mac, show "iCloud is full", and send them once there's room.

E.6 WHEN another Mac has written habits in a newer format than this HabitCal knows THE SYSTEM SHALL not overwrite or misread them, keep working locally, and show "Update HabitCal to sync" until it's updated.

E.7 WHEN the day changes, or two Macs are in different time zones THE SYSTEM SHALL keep check-offs on their calendar day ("Oct 31" stays Oct 31 everywhere), as today.

E.8 WHEN a check-off arrives for a day the other Mac's schedule doesn't include THE SYSTEM SHALL keep it, by B.21.

E.9 WHEN a sync fails partway THE SYSTEM SHALL keep both Macs' habits whole and retry; no habit is ever half-applied.

E.10 WHEN HabitCal is quit or the Mac sleeps with changes not yet sent THE SYSTEM SHALL send them at the next launch or wake.

E.11 THE SYSTEM SHALL read the Settings status with VoiceOver, and update it without moving keyboard focus.

## 10. Contracts

- **Synced habit records in the user's private iCloud database (container `iCloud.com.muchfiner.HabitCal`):** every HabitCal version that syncs reads what earlier versions wrote; a version that finds a newer format doesn't overwrite it (E.6). Relied on by: HabitCal on the user's other Macs, at any version. Versioned like the saved-data format.
- **Saved habit data:** gains what B.16 needs, so its format version goes up; every earlier version still loads (B.18). An export (T-035) carries the same format.

## 11. Success Criteria

- A person with two Macs never has to think about which Mac they checked off on: every habit and check-off matches within a minute while both are online.
- No check-off is ever lost to sync, outside the conflict table's rules.

## 12. Deferred

- A sync switch in HabitCal, for people who want iCloud on but HabitCal local-only — only if asked for.
- Syncing settings (week start) — wait for demand.
- iPhone and iPad apps — PRD Not Doing.
- Sharing a habit with another person — not this product.

## 13. Assumptions

- "Import should replace settings on every Mac" (customer, 2026-11-01) is read as habits: exports carry no settings (T-035).
- The conflict rules in section 7 were proposed by the agent at the customer's request; the customer reviews them with this spec.
- The first-sync merge needs no confirmation: merging loses nothing (B.7, B.8).
- The Mac's clock is roughly right. Clocks far apart could make B.10 pick the wrong "later" change; this is accepted.
- No-account behavior wasn't observed in the spike (no per-app iCloud switch appeared); it's tested with a stand-in for iCloud and checked manually before release.

## Review

st-crit, 2026-11-01, BLOCK, then revised. All six findings accepted:
1. Merging could delete real check-offs (E.8, B.8). Now B.21 says a check-off is never dropped by a merge, and B.8a merges past schedules.
2. The open Edit form could undo another Mac's changes. B.11 now applies only the changed field.
3. Import against concurrent changes had no rules. The conflict table now has import rows.
4. A same-name merge could drop history before the later added date. B.8 keeps the earlier date, and B.8a applies.
5. Habits saved before sync have no change times. B.8b covers them.
6. List order after a merge was undefined. B.12 now defines it.

The customer chose (2026-11-01): merge same-named habits (B.9), merge into a new Apple Account (E.2), and the conflict rules as proposed.
