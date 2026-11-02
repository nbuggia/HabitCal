# Tasks

<!--
Phases are "## Phase N — Name". The current phase is the first one without a ✓.
Tasks are "- [ ] T-NNN Title · high|medium|low", in priority order.
Detail and "Blocked:" reasons go on indented lines under a task.
Nothing is deleted or moved. Finished tasks become "- [x] … · done YYYY-MM-DD",
finished phases get " ✓ YYYY-MM-DD" after their name.
-->

## Phase 1 — v1
- [x] T-001 Prototype menu bar design concepts · high · done 2026-10-29
      Produced D-003 and D-008; the design is specified in T-002, T-003, and T-004.
- [x] T-002 Menu bar date and month calendar · high · done 2026-10-29
      Last commit 0f513a4.
- [x] T-003 Habits: add, edit, check off · high · done 2026-10-29
      Last commit af353d3. FM-010.
- [x] T-004 Streaks · high · done 2026-10-29
      Last commit ff020ef.
- [x] T-006 Calendar polish: tighter day grid · high · done 2026-10-30
      The full-date header was dropped by the customer.
- [x] T-007 Narrow the popover so the calendar's side gutters shrink · high · done 2026-10-30
- [x] T-008 Custom flame for the app icon and streaks · high · done 2026-10-30
      Last commit 47693ce.
- [x] T-009 Narrow the popover's side gutters further (popover 260 pt) · high · done 2026-10-30
      Settings' week-start row stacks its label above the control to fit.
- [x] T-010 Bolder calendar text on Liquid Glass (medium day numbers; bold, primary weekday initials) · high · done 2026-10-30
- [x] T-011 Settings button uses the Phosphor sliders icon · high · done 2026-10-30
- [x] T-012 Show only habits due today; the rest collapse into a "N not due today" row · high · done 2026-10-30
- [x] T-013 Today's calendar marker is a rounded square like the menu bar icon · high · done 2026-10-30
- [x] T-014 Add and Settings buttons move into the Habits header row; footer removed · high · done 2026-10-30
- [x] T-015 Prototype a leaderboard of progress across all habits · medium · done 2026-10-30
      Prototype; the customer picked Consistency, with Past 7 days / Past 30 days / All time tabs. Built in T-016. Commit b6341c5.
- [x] T-016 Consistency leaderboard: habits ranked by share of due days done · high · done 2026-10-30
      Includes the fix for the customer's bug 8 (tabs overflowed the popover). Its two UI tests haven't run yet.
- [ ] T-029 Open like Apple's menu bar extras: flush under the menu bar, no arrow, solid background, steady icon highlight · high
      Customer, 2026-10-30. Spike first: can SwiftUI MenuBarExtra meet D-005's needs (close on Esc, know when it opens)? Replaces T-017.
- [x] T-030 Retro: find the moments a prototype or spike should have been proposed · medium · done 2026-11-01
      Retro written (dc94896); the customer chose not to apply its proposals.
- [x] T-017 Bug: the popover opens too far below the menu bar icon · high · done 2026-10-30
      Dropped: superseded by T-029, which replaces the NSPopover (the gap's cause) with a MenuBarExtra.
- [x] T-018 Bug: the bottom of the habit strips is clipped · high · done 2026-10-30
      Fix: 3 pt of padding inside the list's scroll view. Not yet confirmed on screen.
- [x] T-019 Add button shows a plus in a circle · medium · done 2026-10-30
- [x] T-020 Calendar columns closer together · medium · done 2026-10-30
      Customer, 2026-10-30: the popover stays 260 pt; the narrower grid is centered with small gutters.
- [x] T-021 Hover and pressed states on every button · medium · done 2026-10-30
      Icon buttons, Back, the done button, the habit name, the folded row, and the leaderboard tabs.
- [x] T-022 Select a day in the calendar to see and fix its habits; today keeps a light marker · high · done 2026-10-30
      Customer's items 6 and 7. Customer, 2026-10-30: on a selected past day, the done buttons check off that day. Defaults: the list shows habits due that day; future days view-only; every open goes back to today.
- [x] T-028 Bug: schedules apply to past days too, so a new habit's earlier days show and can be checked off · high · done 2026-10-30
      Customer, 2026-10-30: no start date; a habit is due on every day its schedule includes. Leaderboard All time still starts when added.
- [x] T-027 The menu bar icon stays highlighted while the popover is open · high · done 2026-10-30
- [x] T-025 Streak colors: flame in color above 1; trophy in color when the current streak is above 1 and at or above the best · medium · done 2026-10-30
- [x] T-026 Today's number keeps the normal color when another day is selected (the pale square stays) · medium · done 2026-10-30
- [x] T-023 "October 2026" and the arrows line up with the first and last dates · medium · done 2026-10-30
- [x] T-024 Habits section lines up with the calendar's edges · medium · done 2026-10-30
      Customer chose to narrow the popover: 232 pt, one 200 pt column for every screen.
- [x] T-031 Remove the "Habits" label; Add, Leaderboard, and Settings move to a bottom row; empty list says "No habits" · high · done 2026-10-31
      Customer, 2026-10-31. Reverses T-014's header row; no divider above the bottom row.
- [x] T-032 Settings, the habit form, and the leaderboard are at least as tall as the main screen · medium · done 2026-10-31
- [x] T-033 Week start is a pop-up menu; no Mac-setting captions or Use Mac setting; no ⌘Q label on Quit · medium · done 2026-10-31
      Once the user picks a day, it no longer follows the Mac. ⌘Q still quits (CONTRACTS.md).
- [x] T-034 Bug: today's strip ring is clipped on the right on the month's last day · high · done 2026-10-31
- [x] T-036 The list shows only habits due on the day shown; the "N not due" row is removed · high · done 2026-11-01
      UI tests written, not yet run.
- [x] T-037 Bug: screens taller than the list were clipped (the form's delete confirmation) · high · done 2026-11-01
      Regression from T-032. UI tests written, not yet run.
- [x] T-038 Edits save as they're made; Save removed, Cancel is Close · high · done 2026-11-01
      UI tests written, not yet run. T-039 B.11 will narrow each edit to the changed field.
- [ ] T-035 Export and import habit data from Settings · high
      Both slices coded (5bc17cb, f7c0573). Outstanding: UI tests, manual checks with the real dialogs, diff review, close.
- [ ] T-039 Sync habits across Macs with CloudKit · high
      All 5 slices coded (slices.md; slice 5 in T-035). Outstanding: UI tests, CloudKit Console and second-Mac checks, then the diff review and close.
- [ ] T-041 Habit strip: only due days, oldest left to newest right, not clickable, marker on the selected day · high
      Coded (343c2c7). Outstanding: UI tests, a look on screen, diff review, close.
- [ ] T-005 Release v1: app icon, Developer ID signing, notarization, GitHub download · high
      App icon chosen 2026-10-31: fire with a black outline, in AppIcon.appiconset and Settings' About. A Developer ID Application certificate (NETORION LLC) is in the keychain; notarytool credentials not checked. Left: signing, notarization, the GitHub download and README, the manual test of a downloaded build.
- [x] T-040 Settings' Quit button sits at the bottom of the panel, like the main screen's bottom row · medium · done 2026-11-01
      Commit 084c48c. Not yet checked on screen.
