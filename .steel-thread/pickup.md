# Pickup Note

Session: S-004 · 2026-10-31

## Accomplished

- 2026-10-31: The customer approved the PRD updates: Leaderboard section, day selection under Month Calendar, the folded row under Habits, and the stale grid flow removed.
- 2026-10-31: Dropped the two pending DECISIONS.md proposals with the customer's approval: D-008 already records the icon and Phosphor, and the PRD objective holds the v1 scope choices.
- 2026-10-31: T-015 closed (a65171b): its choices all landed in T-016's code and tests; the rejected options were added to the pending PRD Leaderboard proposal.
- T-029 slice 2 started: the full suite ran partway, then the customer asked to stop it. 11 UI tests passed and 5 failed, all with the same error, "popover didn't open" (`openPopover()`, HabitCalUITests/HabitCalUITestCase.swift:46): DaySelection testSelectingAPastDayShowsAndFixesItsHabits; HabitForm testAddingAHabitShowsItWithItsScheduleLabel, testAddIsDisabledWithoutADay, testEditingAHabitRenamesItAndChangesItsDays; Habits testCheckingOffTodayFillsTheButtonAndTodaysSquare. Other tests opened the panel the same way and passed, so it looks intermittent: a flaky status-item click on MenuBarExtra, or the Mac being used during the run. Not diagnosed. The full log was in the session scratchpad and is gone; the partial result bundle is build/T029-full.xcresult.

- 2026-10-31: run.py added (b7d10a8). T-031 done (6fecb5b): no Habits label, buttons in a bottom row, "No habits". T-005 started (a8cd4fb): the customer chose the fire app icon with a black outline; it's the app's icon and shows in Settings' About. Its UI-visible changes were confirmed by the customer on screen; UI tests not run.

## In Flight

T-035 Export and import: both slices coded (5bc17cb export, f7c0573 import, which also finished T-039's slice 5). Outstanding: DataUITests (8), manual checks with the real panels (panel closes first and icon un-highlights; dialog in front; Save; overwrite prompt; read-only folder; non-JSON; offline iCloud Drive file; Return cancels the confirmation; VoiceOver; Release `codesign -d --entitlements -` shows user-selected read-write), import with sync on across Macs; then st-crit diff review and st-close.

T-039 iCloud sync (Complex, D-010): diff review BLOCK resolved (first sync now merges batches by ID and pairs by name once; failed sends keep their status). Manual check to add: drop the network mid-fetch during a first sync, then confirm nothing is paired twice or lost (review finding 6). All 5 slices coded (slice 5 inside T-035); slices 1–4 committed (b0428b7, 2342513, 10b3025, slice 4 after e6506ef); slice 5 (import everywhere) waits for T-035. The customer chose "commit and keep going, test later". Outstanding before the close: the UI tests (slices 1–3 changed habits, form, day selection, Settings); a look at the app on real data; CloudKit Console checks (edit a record → appears within a minute; stale system fields; delete the zone → resent); Sync Now; change-then-quit; Wi-Fi off; the two-Mac checks (second Mac or second macOS user). Then the st-crit diff review and st-close. Verified so far on the customer's account (Development): upload, download into a fresh Mac, repeat first sync merges by ID. Debug builds need Xcode signed into the team account (it lapsed once). Running the binary with OS_ACTIVITY_DT_MODE=YES shows HabitSync's logs; `log show` showed nothing here.

T-036, T-037, T-038 committed 2026-11-01 (baf54e0) after an st-crit diff review (CONCERNS, 4 minor findings fixed). Their UI tests, and T-029's full suite, still need a run on the customer's screen.

T-035 Export and import (Complex): spec Approved 2026-10-31 after an st-crit review (CONCERNS, 4 findings accepted), docs/work/T-035-export-import/spec.md. Customer chose: import replaces after a confirmation; no backup or undo. Next: the tech design (st-design, Complex). Open technical question for the design: whether the MenuBarExtra panel can stay open while NSSavePanel/NSOpenPanel is up, and that the dialogs come to the front (E.8) — spike it (FM-012). Needs the user-selected read-write sandbox entitlement.

T-029 slice 2 is paused: the full UI suite still needs a complete run on the customer's screen. 5 tests failed with "popover didn't open" (`openPopover()`, HabitCalUITests/HabitCalUITestCase.swift:46) in a partial run; rerun one alone first. Then the design's open questions (refocus hooks, `MainMenu`), the §13 manual checks, and the Complex close with §16's Lasting Changes.

## Suggested Start

T-035's tech design, starting with a spike of the file dialogs from the MenuBarExtra panel. Or, with the customer's screen, the T-029 UI test rerun.

## Proposed Updates

- CONTEXT.md, Vocabulary, "Due day" (T-028): "A day the habit's schedule includes. Only due days count toward a streak." (drop "on or after the habit was added").

- BACKLOG.md (Later, Source T-022): make the calendar grid one Tab stop driven by the arrow keys, like the strip; with Keyboard navigation on, its 42 day buttons now come before the habit list.

- BACKLOG.md, from T-003's Deferred (Later, Source T-003): drag to reorder habits; show notes outside the form (e.g. a row tooltip); undo for delete.
- Spec clarification made during T-003 review (E.8): Tab reaches buttons with the Mac's Keyboard navigation on; the strip is always a Tab stop. Tell the customer.

- BACKLOG.md, from T-002's Deferred (Later, Source T-002): ←/→ keyboard shortcuts to page months and jump to today; a global hotkey to open the popover; localizing beyond English; week numbers in the grid.
- DECISIONS.md: the app icon is a white calendar page with a black header and border and HabitCal's flame (customer, 2026-10-31). Rejected: green or orange header, black header with no border, the green check mark.
- DECISIONS.md (T-035): HabitCal may read and write files the user picks in a save or open dialog, only during that export or import (user-selected read-write entitlement). Refines D-007, whose Why listed only the container, UserDefaults, SMAppService, and opening URLs; still no network entitlement.
