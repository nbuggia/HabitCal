# Pickup Note

Session: S-002 · 2026-10-29

## Accomplished

- Renamed the app CalAccrue → HabitCal (D-002 supersedes D-001) in `docs/PRD.md` and the T-001 prototype. The project folder is `~/workspace/HabitCal`.
- Split v1 into T-002 (menu bar and calendar), T-003 (habits), and T-004 (streaks). Wrote and approved a spec for each in `docs/work/T-00N-*/spec.md`, after one st-crit pass (findings table at the end of T-002's spec).
- Customer ruled: the prototype is the source of truth over the PRD. So the calendar grid has no completion marks (the strips carry history), and Notes stay.

## In Flight

T-001: menu bar icon locked (tear-off calendar page: month cut out of a solid bar, centred; day below; all corners rounded; no progress indicator). Popover: "Final" card in the prototype = Concept 3 (Habit Rows) + Phosphor icons + done button leading each row, streaks on the right, and an edit-habit form (click the name or right-click; add/edit/delete; a schedule change applies from today). Five original concepts removed. Settings panel: app name + www.muchfiner.com at top, Launch at login, Week starts on (follows the Mac until overridden; requirement in the prototype README), Quit. Habit form has Notes instead of preset pills. Awaiting the customer's feedback. Then write the pick into the prototype README's Answer section and propose a DECISIONS.md entry for the menu bar design.

## Up Next

PRD aligned with the prototype (D-003), and data rules logged (D-004). Next is the tech design. Run st-dev-setup first, because there's no `docs/engineering/ARCHITECTURE.md` yet. Then st-design for T-002. T-003 is likely Complex: it creates the persisted data format.

## Suggested Start

Get the customer's sign-off on `docs/PRD.md` (my calls: yes/no habits only, no calendar events, SwiftUI macOS 15+, notarized GitHub download), then capture context (vocabulary: habit, schedule, due day, streak).

## Proposed Updates

- T-001: close it with st-close. Its prototype is answered, and its specs are written.

- DECISIONS.md: menu bar icon is the tear-off calendar page with no progress indicator (ring and progress line tried and rejected as too busy); Phosphor for UI icons.

- DECISIONS.md: no calendar events in v1; local-only data, no sync; free with no limits; SwiftUI/macOS 15+, no dependencies; GitHub notarized distribution.
