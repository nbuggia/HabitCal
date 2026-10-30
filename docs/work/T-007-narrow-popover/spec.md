---
name: Narrow popover
task: T-007
status: Approved
last updated: 2026-10-30
---

# Spec: Narrow Popover

## 1. Summary

The popover narrows from about 330 pt to 280 pt, so the calendar fills it with slim side margins instead of wide empty gutters (customer request after T-006 tightened the grid). Habit rows, strips, the form, and Settings fit the narrower width.

## 4. Current Behavior

- The popover is about 330 pt wide (T-002 spec §5); the 236 pt grid leaves about 35 pt of empty space on each side (T-006).
- Strip squares are spaced 2 pt apart (T-003 implementation).

## 7. Behavior

### Changed

B.1 THE SYSTEM SHALL show the popover 280 pt wide, on every screen. Was: about 330 pt (T-002 §5). Why: the calendar's side gutters were too wide.

B.2 THE SYSTEM SHALL space strip squares 1.5 pt apart, so squares stay close to their earlier size in the narrower row. Was: 2 pt.

### Unchanged

B.3 THE SYSTEM SHALL CONTINUE TO fit every row and control without truncating labels that fit before: habit names up to 40 characters may truncate with an ellipsis, as before; the Settings rows, form, and calendar header must not. Covered by: the full UI suite, and a screenshot of each screen.
