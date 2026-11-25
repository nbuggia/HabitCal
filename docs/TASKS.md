# Tasks

<!--
Phases are "## Phase N — Name", each followed by a table. The current phase is the first one without a ✓.

| ID | Task | Priority | Status | Notes |
| --- | --- | --- | --- | --- |

Rows are in priority order; priority is high, medium, or low.
Status is open, in progress, blocked, awaiting test YYYY-MM-DD, done YYYY-MM-DD, or dropped YYYY-MM-DD.
Notes are one short phrase. Nothing is deleted or moved.
Finished phases get " ✓ YYYY-MM-DD" after their name.
-->

## Phase 1 — v1

| ID | Task | Priority | Status | Notes |
| --- | --- | --- | --- | --- |
| T-001 | Prototype menu bar design concepts | high | done 2026-10-29 | D-003 · D-008 |
| T-002 | Menu bar date and month calendar | high | done 2026-10-29 | 0f513a4 |
| T-003 | Habits: add, edit, check off | high | done 2026-10-29 | af353d3 · FM-010 |
| T-004 | Streaks | high | done 2026-10-29 | ff020ef |
| T-006 | Calendar polish: tighter day grid | high | done 2026-10-30 | Customer dropped the full-date header |
| T-007 | Narrow the popover so the calendar's side gutters shrink | high | done 2026-10-30 | |
| T-008 | Custom flame for the app icon and streaks | high | done 2026-10-30 | 47693ce |
| T-009 | Narrow the popover's side gutters further (popover 260 pt) | high | done 2026-10-30 | Week-start row stacks its label above the control |
| T-010 | Bolder calendar text on Liquid Glass (medium day numbers; bold, primary weekday initials) | high | done 2026-10-30 | |
| T-011 | Settings button uses the Phosphor sliders icon | high | done 2026-10-30 | |
| T-012 | Show only habits due today; the rest collapse into a "N not due today" row | high | done 2026-10-30 | |
| T-013 | Today's calendar marker is a rounded square like the menu bar icon | high | done 2026-10-30 | |
| T-014 | Add and Settings buttons move into the Habits header row; footer removed | high | done 2026-10-30 | |
| T-015 | Prototype a leaderboard of progress across all habits | medium | done 2026-10-30 | b6341c5 · Consistency chosen, built in T-016 |
| T-016 | Consistency leaderboard: habits ranked by share of due days done | high | done 2026-10-30 | Two UI tests not yet run |
| T-029 | Open like Apple's menu bar extras: flush under the menu bar, no arrow, solid background, steady icon highlight | high | in progress | Slice 2 paused: full UI suite needs a run on the customer's screen |
| T-030 | Retro: find the moments a prototype or spike should have been proposed | medium | done 2026-11-01 | dc94896 · proposals not applied |
| T-017 | Bug: the popover opens too far below the menu bar icon | high | dropped 2026-10-30 | Superseded by T-029's MenuBarExtra |
| T-018 | Bug: the bottom of the habit strips is clipped | high | done 2026-10-30 | 3 pt padding; not yet confirmed on screen |
| T-019 | Add button shows a plus in a circle | medium | done 2026-10-30 | |
| T-020 | Calendar columns closer together | medium | done 2026-10-30 | Popover stays 260 pt; grid centered |
| T-021 | Hover and pressed states on every button | medium | done 2026-10-30 | |
| T-022 | Select a day in the calendar to see and fix its habits; today keeps a light marker | high | done 2026-10-30 | Past days editable; future days view-only |
| T-028 | Bug: schedules apply to past days too, so a new habit's earlier days show and can be checked off | high | done 2026-10-30 | No start date; due on every scheduled day |
| T-027 | The menu bar icon stays highlighted while the popover is open | high | done 2026-10-30 | |
| T-025 | Streak colors: flame in color above 1; trophy in color when the current streak is above 1 and at or above the best | medium | done 2026-10-30 | |
| T-026 | Today's number keeps the normal color when another day is selected (the pale square stays) | medium | done 2026-10-30 | |
| T-023 | "October 2026" and the arrows line up with the first and last dates | medium | done 2026-10-30 | |
| T-024 | Habits section lines up with the calendar's edges | medium | done 2026-10-30 | Popover 232 pt, one 200 pt column |
| T-031 | Remove the "Habits" label; Add, Leaderboard, and Settings move to a bottom row; empty list says "No habits" | high | done 2026-10-31 | 6fecb5b · reverses T-014's header row |
| T-032 | Settings, the habit form, and the leaderboard are at least as tall as the main screen | medium | done 2026-10-31 | |
| T-033 | Week start is a pop-up menu; no Mac-setting captions or Use Mac setting; no ⌘Q label on Quit | medium | done 2026-10-31 | ⌘Q still quits |
| T-034 | Bug: today's strip ring is clipped on the right on the month's last day | high | done 2026-10-31 | |
| T-036 | The list shows only habits due on the day shown; the "N not due" row is removed | high | done 2026-11-01 | baf54e0 · UI tests not yet run |
| T-037 | Bug: screens taller than the list were clipped (the form's delete confirmation) | high | done 2026-11-01 | baf54e0 · UI tests not yet run |
| T-038 | Edits save as they're made; Save removed, Cancel is Close | high | done 2026-11-01 | baf54e0 · UI tests not yet run |
| T-035 | Export and import habit data from Settings | high | in progress | Coded (5bc17cb, f7c0573); next: UI tests, data.md manual checks, diff review |
| T-039 | Sync habits across Macs with CloudKit | high | in progress | Coded, review BLOCK fixed; next: UI tests, CloudKit and second-Mac checks |
| T-041 | Habit strip: only due days, oldest left to newest right, not clickable, marker on the selected day | high | in progress | Coded and diff-reviewed; next: UI tests and a look on screen |
| T-005 | Release v1 on the Mac App Store: app icon, App Store signing, listing, review | high | in progress | D-011 · D-012 · build 1.0 (4) on TestFlight 2026-11-15; next: CloudKit prod schema, listing |
| T-042 | Bug: Sync Now sticks on "Syncing…" and never retries a change iCloud refused | high | in progress | df5d09d, diff-reviewed; next: manual CloudKit check (refused save, then Sync Now) |
| T-043 | Leaderboard cup: also for a habit on its best streak; otherwise only a perfect record so far | high | in progress | Customer, 2026-11-24; next: tests, code, diff review |
| T-040 | Settings' Quit button sits at the bottom of the panel, like the main screen's bottom row | medium | done 2026-11-01 | 084c48c · not yet checked on screen |
