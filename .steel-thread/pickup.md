# Pickup Note

Session: S-001 · 2026-10-29

## Accomplished

- Installed Steel Thread (Claude Code) and ran `git init`; nothing committed yet.
- Competitive research written to the Appendix of `docs/PRD.md`.
- Drafted the objective and feature intent in `docs/PRD.md`, and `docs/BACKLOG.md` with deferred ideas — awaiting the customer's review.
- Created `docs/TASKS.md` (Phase 1 — v1) with T-001, and built five menu bar concepts in `docs/work/T-001-menubar-concepts/prototype/index.html` (light/dark toggle, live shared data).

## In Flight

T-001: menu bar icon locked (tear-off calendar page: month cut out of a solid bar, centred; day below; all corners rounded; no progress indicator). Popover: "Final" card in the prototype = Concept 3 (Habit Rows) + Phosphor icons + done button leading each row, streaks on the right, and an edit-habit form (click the name or right-click; add/edit/delete; a schedule change applies from today). Five original concepts removed. Settings panel: app name + www.muchfiner.com at top, Launch at login, Week starts on (follows the Mac until overridden; requirement in the prototype README), Quit. Habit form has Notes instead of preset pills. Awaiting the customer's feedback. Then write the pick into the prototype README's Answer section and propose a DECISIONS.md entry for the menu bar design.

## Up Next

Customer wanted to finish the product definition and competitive analysis before anything else.

## Suggested Start

Get the customer's sign-off on `docs/PRD.md` (my calls: yes/no habits only, no calendar events, SwiftUI macOS 15+, notarized GitHub download), then capture context (vocabulary: habit, schedule, due day, streak).

## Proposed Updates

(App renamed tcal → CalAccrue; logged as D-001. Project folder renamed to `~/workspace/CalAccrue`.)

- DECISIONS.md: menu bar icon is the tear-off calendar page with no progress indicator (ring and progress line tried and rejected as too busy); Phosphor for UI icons.

- DECISIONS.md: no calendar events in v1; local-only data, no sync; free with no limits; SwiftUI/macOS 15+, no dependencies; GitHub notarized distribution.
