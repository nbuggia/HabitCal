# Pickup Note

Session: S-003 · 2026-10-30

## Accomplished

- 2026-10-30: T-009 to T-016 and T-018 to T-028 done and committed (see TASKS.md and git log). D-009 logged (MenuBarExtra), superseding D-005.
- T-029 (Complex): spike answered (spike/README.md), design Approved after 2 review passes, slice 1 committed b9bbac0. The customer tried it: "works great, feels much better".
- UI tests have not run since T-016 (the customer was using the Mac). About 15 written since then have never run.

## In Flight

T-029 slice 2: run the full UI suite (needs the customer's screen, about 10 minutes). It answers the design's open questions: does XCUITest's click open a MenuBarExtra; do the Esc tests pass without the refocus hooks (if yes, delete `AppModel.screenDidChange`/`listDidHideRows`); does ⌘Q and Edit work without `MainMenu` (if yes, delete it). Then the manual checks in design §13, then close T-029 (every st-close step: Complex), applying §16's Lasting Changes (ARCHITECTURE, CONVENTIONS, TESTING, FM-006, FM-008).

## Suggested Start

Ask the customer for the screen and run the full UI suite.

## Proposed Updates

- CONTEXT.md, Vocabulary, "Due day" (T-028): "A day the habit's schedule includes. Only due days count toward a streak." (drop "on or after the habit was added").

- BACKLOG.md (Later, Source T-022): make the calendar grid one Tab stop driven by the arrow keys, like the strip; with Keyboard navigation on, its 42 day buttons now come before the habit list.
- PRD.md: a "Feature: Leaderboard" section (T-016), and day selection under "Feature: Month Calendar" (T-022).

- PRD.md, "Feature: Habits" (from T-012): add "The list shows the habits due today; the others fold into a quiet 'N not due today' row that opens to show them." Not Doing: hiding not-due habits with no way back (they couldn't be edited that day); remembering whether the row is open.
- PRD.md line 52 still says each grid day shows how its habits went, which D-003 removed. Propose deleting it.

- BACKLOG.md, from T-003's Deferred (Later, Source T-003): drag to reorder habits; show notes outside the form (e.g. a row tooltip); undo for delete.
- Spec clarification made during T-003 review (E.8): Tab reaches buttons with the Mac's Keyboard navigation on; the strip is always a Tab stop. Tell the customer.

- BACKLOG.md, from T-002's Deferred (Later, Source T-002): ←/→ keyboard shortcuts to page months and jump to today; a global hotkey to open the popover; localizing beyond English; week numbers in the grid.


- DECISIONS.md: menu bar icon is the tear-off calendar page with no progress indicator (ring and progress line tried and rejected as too busy); Phosphor for UI icons.

- DECISIONS.md: no calendar events in v1; local-only data, no sync; free with no limits; SwiftUI/macOS 15+, no dependencies; GitHub notarized distribution.
