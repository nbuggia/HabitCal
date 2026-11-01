# Pickup Note

Session: S-004 · 2026-10-31

## Accomplished

- 2026-10-31: The customer approved the PRD updates: Leaderboard section, day selection under Month Calendar, the folded row under Habits, and the stale grid flow removed.
- 2026-10-31: Dropped the two pending DECISIONS.md proposals with the customer's approval: D-008 already records the icon and Phosphor, and the PRD objective holds the v1 scope choices.
- 2026-10-31: T-015 closed (a65171b): its choices all landed in T-016's code and tests; the rejected options were added to the pending PRD Leaderboard proposal.
- T-029 slice 2 started: the full suite ran partway, then the customer asked to stop it. 11 UI tests passed and 5 failed, all with the same error, "popover didn't open" (`openPopover()`, HabitCalUITests/HabitCalUITestCase.swift:46): DaySelection testSelectingAPastDayShowsAndFixesItsHabits; HabitForm testAddingAHabitShowsItWithItsScheduleLabel, testAddIsDisabledWithoutADay, testEditingAHabitRenamesItAndChangesItsDays; Habits testCheckingOffTodayFillsTheButtonAndTodaysSquare. Other tests opened the panel the same way and passed, so it looks intermittent: a flaky status-item click on MenuBarExtra, or the Mac being used during the run. Not diagnosed. The full log was in the session scratchpad and is gone; the partial result bundle is build/T029-full.xcresult.

- 2026-10-31: run.py added (b7d10a8). T-031 done (6fecb5b): no Habits label, buttons in a bottom row, "No habits". T-005 started (a8cd4fb): the customer chose the fire app icon with a black outline; it's the app's icon and shows in Settings' About. Its UI-visible changes were confirmed by the customer on screen; UI tests not run.

## In Flight

T-039 iCloud sync (Complex, D-010): spike done (docs/work/T-039-icloud-sync/spike/README.md). CloudKit works development-signed and Developer ID-signed (production), with no network entitlement; CKSyncEngine starts. No-account behavior is an accepted risk (no per-app iCloud switch appeared). Release needs: the schema deployed to production (never the spike's SpikeHabit type), a hand-signed build with a downloaded Developer ID profile naming the certificate expiring 2027-02-01. Spec Approved 2026-11-01 (docs/work/T-039-icloud-sync/spec.md) after st-crit BLOCK → 6 findings fixed; customer chose merge at first sync, merge same-named habits, merge into a new Apple Account, the proposed conflict rules, status in Settings only, import replaces on every Mac. Next: T-039 tech design (Complex). T-035's confirmation wording changes with sync on (T-039 B.14), and T-038's form must apply only the changed field (T-039 B.11).

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
