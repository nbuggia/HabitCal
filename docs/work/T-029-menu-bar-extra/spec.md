---
name: Menu bar extra
task: T-029
status: Approved
last updated: 2026-10-30
---

# Spec: Open Like Apple's Menu Bar Extras

## 1. Summary

HabitCal's panel opens the way Apple's own menu bar extras do: attached flush under the menu bar with no arrow, on a solid background, with the menu bar icon highlighted steadily while it's open. The customer compared it with Apple's Now Playing extra on 2026-10-30. Everything inside the panel works as before. This replaces T-017 (the gap under the icon) and supersedes D-005 with D-009.

## 3. Not Doing

- Changing any screen inside the panel.
- A detachable or resizable panel.

## 4. Current Behavior

- An NSPopover with an arrow, about 14 pt below the menu bar, on translucent Liquid Glass (T-017).
- The icon goes dark gray while pressed, then shows a lighter highlight while open (T-027).
- Esc backs out of the form and Settings, and closes the popover from the list (T-002 B.5). Every open starts on the habit list and the current month, with today selected (T-002 B.4, T-022 B.7). Clicking the website link closes it (T-002 B.18).

## 5. UI

- The panel hangs from the menu bar directly under the icon, with rounded corners and no arrow, on the system's menu bar extra background, like Now Playing.
- The icon shows the system's highlight from the click that opens the panel until it closes.
- The panel is the same 232 pt wide (T-024).

The word "popover" stays the user-facing term for the panel (CONTEXT.md).

## 7. Behavior

### Changed

B.1 WHEN the user clicks the menu bar icon THE SYSTEM SHALL open the panel flush under the menu bar, without an arrow, and highlight the icon until it closes. Was: an NSPopover with an arrow and a gap. Why: the customer wants it to match Apple's extras.

### Unchanged

B.2 THE SYSTEM SHALL CONTINUE TO close the panel on a second click on the icon, a click elsewhere, or switching apps.

B.3 THE SYSTEM SHALL CONTINUE TO start every open on the habit list, the current month, and today (T-002 B.4, T-012 B.2, T-022 B.7).

B.4 THE SYSTEM SHALL CONTINUE TO handle Esc one level at a time: the form, Settings, and the leaderboard go back to the list, and the list closes the panel (T-002 B.5, T-016 B.6).

B.5 THE SYSTEM SHALL CONTINUE TO close the panel after opening the website link (T-002 B.18), and to quit on Quit and ⌘Q (B.19).

B.6 THE SYSTEM SHALL CONTINUE TO show today's date in the icon, updated at midnight and after sleep (T-002 B.1, B.2), to keep a single icon when a second copy starts (E.2), and to give the form's text fields Undo, Cut, Copy, Paste, and Select All.

B.7 THE SYSTEM SHALL CONTINUE TO take keyboard input when opened: typing in the form, Tab with Keyboard navigation on, and Esc (FM-006).
