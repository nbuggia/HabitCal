# Pickup Note

Session: S-002 · 2026-10-29

## Accomplished

- Renamed the app CalAccrue → HabitCal (D-002 supersedes D-001) in `docs/PRD.md` and the T-001 prototype. The project folder is `~/workspace/HabitCal`.
- Split v1 into T-002 (menu bar and calendar), T-003 (habits), and T-004 (streaks). Wrote and approved a spec for each in `docs/work/T-00N-*/spec.md`, after one st-crit pass (findings table at the end of T-002's spec).
- Ran st-dev-setup: wrote `docs/engineering/` (ARCHITECTURE, CONVENTIONS, TESTING, COMMON-FAILURE-MODES FM-001–009) and adapted st-design, st-crit, st-slice, and development.md to Swift/SwiftUI (logged in customizations.md).
- T-001 closed (D-008). Added T-005 (release). T-002 design approved after two review passes (15 findings, all accepted); spec E.10 added and E.9 narrowed to /Applications. REVIEW-PATTERNS.md created.
- T-002 built (4 slices), reviewed (6 findings fixed), and closed. 17 unit and 15 UI tests pass.
- T-003 (3 slices) and T-004 built, reviewed, and closed. 55 unit and 31 UI tests pass. habits.json v1 is in CONTRACTS.md.
- Customer ruled: the prototype is the source of truth over the PRD. So the calendar grid has no completion marks (the strips carry history), and Notes stay.

## In Flight

T-001: menu bar icon locked (tear-off calendar page: month cut out of a solid bar, centred; day below; all corners rounded; no progress indicator). Popover: "Final" card in the prototype = Concept 3 (Habit Rows) + Phosphor icons + done button leading each row, streaks on the right, and an edit-habit form (click the name or right-click; add/edit/delete; a schedule change applies from today). Five original concepts removed. Settings panel: app name + www.muchfiner.com at top, Launch at login, Week starts on (follows the Mac until overridden; requirement in the prototype README), Quit. Habit form has Notes instead of preset pills. Awaiting the customer's feedback. Then write the pick into the prototype README's Answer section and propose a DECISIONS.md entry for the menu bar design.

## Up Next

T-005 (release): app icon proposed (needs the customer's OK), README, a release script; signing and notarization need the customer's Apple Developer account. The customer's last message, "Add this to the list of feature changes:", arrived cut off; ask what to add.

## Suggested Start

Get the customer's sign-off on `docs/PRD.md` (my calls: yes/no habits only, no calendar events, SwiftUI macOS 15+, notarized GitHub download), then capture context (vocabulary: habit, schedule, due day, streak).

## Proposed Updates

- BACKLOG.md, from T-003's Deferred (Later, Source T-003): drag to reorder habits; show notes outside the form (e.g. a row tooltip); undo for delete.
- Spec clarification made during T-003 review (E.8): Tab reaches buttons with the Mac's Keyboard navigation on; the strip is always a Tab stop. Tell the customer.

- BACKLOG.md, from T-002's Deferred (Later, Source T-002): ←/→ keyboard shortcuts to page months and jump to today; a global hotkey to open the popover; localizing beyond English; week numbers in the grid.


- DECISIONS.md: menu bar icon is the tear-off calendar page with no progress indicator (ring and progress line tried and rejected as too busy); Phosphor for UI icons.

- DECISIONS.md: no calendar events in v1; local-only data, no sync; free with no limits; SwiftUI/macOS 15+, no dependencies; GitHub notarized distribution.
