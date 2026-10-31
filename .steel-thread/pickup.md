# Pickup Note

Session: S-004 · 2026-10-31

## Accomplished

- 2026-10-31: The customer approved the PRD updates: Leaderboard section, day selection under Month Calendar, the folded row under Habits, and the stale grid flow removed.
- 2026-10-31: Dropped the two pending DECISIONS.md proposals with the customer's approval: D-008 already records the icon and Phosphor, and the PRD objective holds the v1 scope choices.
- 2026-10-31: T-015 closed (a65171b): its choices all landed in T-016's code and tests; the rejected options were added to the pending PRD Leaderboard proposal.
- T-029 slice 2 started: the full suite ran partway, then the customer asked to stop it. 11 UI tests passed and 5 failed, all with the same error, "popover didn't open" (`openPopover()`, HabitCalUITests/HabitCalUITestCase.swift:46): DaySelection testSelectingAPastDayShowsAndFixesItsHabits; HabitForm testAddingAHabitShowsItWithItsScheduleLabel, testAddIsDisabledWithoutADay, testEditingAHabitRenamesItAndChangesItsDays; Habits testCheckingOffTodayFillsTheButtonAndTodaysSquare. Other tests opened the panel the same way and passed, so it looks intermittent: a flaky status-item click on MenuBarExtra, or the Mac being used during the run. Not diagnosed. The full log was in the session scratchpad and is gone; the partial result bundle is build/T029-full.xcresult.

## In Flight

T-029 slice 2: the full UI suite still needs a complete run on the customer's screen. First find out why `openPopover()` sometimes fails: rerun one of the 5 failing tests alone (`-only-testing:HabitCalUITests/HabitFormUITests/testAddIsDisabledWithoutADay`). If it fails on a quiet Mac, make the open more reliable (retry the click, or wait for the panel longer). The run also answers the design's open questions: do the Esc tests pass without the refocus hooks (if yes, delete `AppModel.screenDidChange`/`listDidHideRows`); do ⌘Q and Edit work without `MainMenu` (if yes, delete it). Then the manual checks in design §13, then close T-029 (every st-close step: Complex), applying §16's Lasting Changes (ARCHITECTURE, CONVENTIONS, TESTING, FM-006, FM-008).

## Suggested Start

When the customer can give up the screen, rerun one failing test alone to see whether the "popover didn't open" failure is flaky or real.

## Proposed Updates

- CONTEXT.md, Vocabulary, "Due day" (T-028): "A day the habit's schedule includes. Only due days count toward a streak." (drop "on or after the habit was added").

- BACKLOG.md (Later, Source T-022): make the calendar grid one Tab stop driven by the arrow keys, like the strip; with Keyboard navigation on, its 42 day buttons now come before the habit list.

- BACKLOG.md, from T-003's Deferred (Later, Source T-003): drag to reorder habits; show notes outside the form (e.g. a row tooltip); undo for delete.
- Spec clarification made during T-003 review (E.8): Tab reaches buttons with the Mac's Keyboard navigation on; the strip is always a Tab stop. Tell the customer.

- BACKLOG.md, from T-002's Deferred (Later, Source T-002): ←/→ keyboard shortcuts to page months and jump to today; a global hotkey to open the popover; localizing beyond English; week numbers in the grid.
