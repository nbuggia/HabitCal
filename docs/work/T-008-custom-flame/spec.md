---
name: Custom flame
task: T-008
status: Approved
last updated: 2026-10-30
---

# Spec: Custom Flame

## 1. Summary

HabitCal gets its own, more realistic flame: layered red, orange, and yellow, at the customer's request. It replaces Phosphor's line-art fire beside each habit's current streak, and it's the flame in the app icon proposals, so the two always match.

## 4. Current Behavior

- The current streak shows Phosphor's "fire" icon: flame-orange when the streak is 3 or more, otherwise grey (T-004 spec §5; D-008, Phosphor for in-app icons).

## 7. Behavior

### Changed

B.1 THE SYSTEM SHALL show HabitCal's flame (docs/artwork/flame.svg) beside the current streak. At 3 or more it's in full color; below 3 it's grey (desaturated, dimmed). Was: Phosphor's fire, tinted orange or grey. Why: the customer wanted a more realistic flame.

B.2 The app icon's fire SHALL be the same flame drawing.

### Unchanged

B.3 THE SYSTEM SHALL CONTINUE TO show the streak number flame-orange and bold at 3 or more, grey below, with the tooltip "Current streak" and the spoken label from T-004. Covered by: `testCheckingOffUpdatesTheStreakImmediately`, `streakSpokenLabelUsesDayAndDays`.
