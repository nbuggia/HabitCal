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
      Last commit 549073b.
- [x] T-003 Habits: add, edit, check off · high · done 2026-10-29
      Last commit 6dd42c5. FM-010.
- [x] T-004 Streaks · high · done 2026-10-29
      Last commit 3cc03da.
- [x] T-006 Calendar polish: tighter day grid · high · done 2026-10-30
      The full-date header was dropped by the customer.
- [x] T-007 Narrow the popover so the calendar's side gutters shrink · high · done 2026-10-30
- [x] T-008 Custom flame for the app icon and streaks · high · done 2026-10-30
      Last commit 0585a91.
- [x] T-009 Narrow the popover's side gutters further (popover 260 pt) · high · done 2026-10-30
      Settings' week-start row stacks its label above the control to fit.
- [x] T-010 Bolder calendar text on Liquid Glass (medium day numbers; bold, primary weekday initials) · high · done 2026-10-30
- [x] T-011 Settings button uses the Phosphor sliders icon · high · done 2026-10-30
- [x] T-012 Show only habits due today; the rest collapse into a "N not due today" row · high · done 2026-10-30
- [x] T-013 Today's calendar marker is a rounded square like the menu bar icon · high · done 2026-10-30
- [x] T-014 Add and Settings buttons move into the Habits header row; footer removed · high · done 2026-10-30
- [x] T-015 Prototype a leaderboard of progress across all habits · medium · done 2026-10-30
      The customer picked Consistency, with Past 7 days / Past 30 days / All time tabs.
- [x] T-016 Consistency leaderboard: habits ranked by share of due days done · high · done 2026-10-30
      Includes the fix for the customer's bug 8 (tabs overflowed the popover). Its two UI tests haven't run yet.
- [ ] T-017 Bug: the popover opens too far below the menu bar icon · high
      About 14 pt of gap between the menu bar and the popover's arrow. Diagnose first: status item button bounds, NSPopover positioning on macOS 26.
- [ ] T-018 Bug: the bottom of the habit strips is clipped · high
      Likely the habit list's ScrollView clips today's ring (drawn 1.5 pt outside the square) and the bottom edge of the last row. Confirm, then fix the list's height or padding.
- [ ] T-019 Add button shows a plus in a circle · medium
- [x] T-020 Calendar columns closer together · medium · done 2026-10-30
      Customer, 2026-10-30: the popover stays 260 pt; the narrower grid is centered with small gutters.
- [ ] T-021 Hover and pressed states on every button · medium
      Icon buttons, Back, the done button, the habit name, the folded row, and the leaderboard tabs.
- [ ] T-022 Select a day in the calendar to see and fix its habits; today keeps a light marker · high
      Customer's items 6 and 7. Customer, 2026-10-30: on a selected past day, the done buttons check off that day. Defaults: the list shows habits due that day; future days view-only; every open goes back to today.
- [ ] T-005 Release v1: app icon, Developer ID signing, notarization, GitHub download · high
      Needs the customer's Apple Developer account. Covers the Finder app icon, the GitHub README, and the manual test of a downloaded build.
