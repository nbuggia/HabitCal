# Pickup Note

Session: S-003 · 2026-10-30

## Accomplished

- T-009 to T-016 and T-020 done and committed today (see TASKS.md and git log). T-016 (consistency leaderboard) 33c94df; T-020 (28 pt calendar columns, centered) d90a464.
- Customer's bug list captured as T-017 to T-022 (answers recorded on T-020 and T-022 in TASKS.md).
- The customer asked to stop running UI tests while they use the Mac (they drive the real screen). UI tests for T-012 ran individually; T-016's two UI tests are written and compiled but have never run. Run the full suite when the customer is away.

## In Flight

T-021 (hover and pressed states, Simple): `HoverButtonStyle` written and applied everywhere; spec, design, CONVENTIONS.md and manual test written; uncommitted; st-crit review running. Next: apply findings, commit, close (close.md).

Then: T-019 (plus-circle asset already added, uncommitted: swap "plus" for "plus-circle" in `HabitListScreen.header`), T-018 (strip clipping: likely the list's ScrollView clipping today's ring; add bottom padding inside the scroll content), T-022 (day selection: needs spec), T-017 (popover gap: needs an on-screen measurement, so wait for the customer to be away).

## Suggested Start

With the Mac free: run the full UI suite, and screenshot the list, leaderboard and form to check T-016, T-020 and T-021 by eye.

## Proposed Updates

- BACKLOG.md (Later, Source T-022): make the calendar grid one Tab stop driven by the arrow keys, like the strip; with Keyboard navigation on, its 42 day buttons now come before the habit list.
- PRD.md: a "Feature: Leaderboard" section (T-016), and day selection under "Feature: Month Calendar" (T-022).

- PRD.md, "Feature: Habits" (from T-012): add "The list shows the habits due today; the others fold into a quiet 'N not due today' row that opens to show them." Not Doing: hiding not-due habits with no way back (they couldn't be edited that day); remembering whether the row is open.
- PRD.md line 52 still says each grid day shows how its habits went, which D-003 removed. Propose deleting it.

- BACKLOG.md, from T-003's Deferred (Later, Source T-003): drag to reorder habits; show notes outside the form (e.g. a row tooltip); undo for delete.
- Spec clarification made during T-003 review (E.8): Tab reaches buttons with the Mac's Keyboard navigation on; the strip is always a Tab stop. Tell the customer.

- BACKLOG.md, from T-002's Deferred (Later, Source T-002): ←/→ keyboard shortcuts to page months and jump to today; a global hotkey to open the popover; localizing beyond English; week numbers in the grid.


- DECISIONS.md: menu bar icon is the tear-off calendar page with no progress indicator (ring and progress line tried and rejected as too busy); Phosphor for UI icons.

- DECISIONS.md: no calendar events in v1; local-only data, no sync; free with no limits; SwiftUI/macOS 15+, no dependencies; GitHub notarized distribution.
