# Pickup Note

Session: S-003 · 2026-10-30

## Accomplished

- T-015: leaderboard prototype (three options) in c931c9b; awaiting the customer's pick.
- T-009 (popover 260 pt; Settings week-start label stacked above its control), T-010 (bolder calendar text), T-011 (sliders Settings icon): 17e8823, 74e5495, 5273bcc. Full UI suite 33/33 before committing.
- T-013 (rounded-square today marker) f158f7a; T-014 (Add and Settings in the Habits header row, no footer) 2270b6a. Screenshots checked; covered by the T-012 full run.
- Mistake noted in 5273bcc: the gear asset's removal slipped into c931c9b, so c931c9b..74e5495 show no Settings icon. Not rewritten, because another session commits to main too.

## In Flight

T-012 (Simple): spec and design in `docs/work/T-012-due-today-only/`. Code done, uncommitted: `Habits.dueOn/notDueOn`, `HabitLabels.notDueRow*`, `AppModel.showsNotDue/toggleNotDue` (reset on open, set when a saved habit isn't due), folded row in `HabitListScreen`, `ph-caret-down` asset, UI tests updated (`showNotDue()` helper) and added. Unit 57/57; screenshots good. Next: full UI suite result, then the st-crit diff review's findings, then commit and close (st-close steps 1–4 and 6). The T-012 default was chosen without asking: not-due habits fold into a "N not due today" row rather than vanishing.

Another session used T-008 (custom flame) at the same time; my tasks were renumbered T-009 to T-015; T-008 marked done.

## Suggested Start

Show the customer the T-015 prototype (`docs/work/T-015-leaderboard/prototype/index.html`) for a pick, and confirm the T-012 folded-row default.

## Proposed Updates

- PRD.md, "Feature: Habits" (from T-012): add "The list shows the habits due today; the others fold into a quiet 'N not due today' row that opens to show them." Not Doing: hiding not-due habits with no way back (they couldn't be edited that day); remembering whether the row is open.
- PRD.md line 52 still says each grid day shows how its habits went, which D-003 removed. Propose deleting it.

- BACKLOG.md, from T-003's Deferred (Later, Source T-003): drag to reorder habits; show notes outside the form (e.g. a row tooltip); undo for delete.
- Spec clarification made during T-003 review (E.8): Tab reaches buttons with the Mac's Keyboard navigation on; the strip is always a Tab stop. Tell the customer.

- BACKLOG.md, from T-002's Deferred (Later, Source T-002): ←/→ keyboard shortcuts to page months and jump to today; a global hotkey to open the popover; localizing beyond English; week numbers in the grid.


- DECISIONS.md: menu bar icon is the tear-off calendar page with no progress indicator (ring and progress line tried and rejected as too busy); Phosphor for UI icons.

- DECISIONS.md: no calendar events in v1; local-only data, no sync; free with no limits; SwiftUI/macOS 15+, no dependencies; GitHub notarized distribution.
