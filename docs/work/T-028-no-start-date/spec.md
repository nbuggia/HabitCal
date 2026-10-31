---
name: No start date
task: T-028
status: Approved
last updated: 2026-10-30
---

# Spec: No Start Date

## 1. Summary

A habit is due on every day its schedule includes, before and after the day it was added. The customer added an every-day habit, selected yesterday, and saw nothing: "We don't need a start date for habits, just events for when they are completed according to schedule" (2026-10-30). So a past day can be checked off for a habit added today, from the list (T-022) or the strip.

## 3. Not Doing

- Removing `addedOn` from habits.json. It stays in the file (CONTRACTS.md v1) and still starts the leaderboard's All time range.
- A user-set start date.

## 4. Current Behavior

- A day is due only on or after the habit was added (T-003; CONTEXT.md, Due day). Earlier days show as not scheduled, can't be checked off, and never count toward streaks or the leaderboard.

## 7. Behavior

### Changed

B.1 THE SYSTEM SHALL treat a habit as due on any day its schedule includes, whatever the day it was added. Before the first schedule entry, the first entry applies. Was: never due before it was added. Why: the customer wants to log past days.

B.2 THE SYSTEM SHALL allow checking off, and show as done or missed, a habit's due days before it was added (T-003 B.5, T-022 B.4).

B.3 THE SYSTEM SHALL count streaks back to the habit's earliest check-off; due days before it are missed and can't extend a run. Was: streaks started on the day it was added.

B.4 THE SYSTEM SHALL start the leaderboard's All time range at the earlier of the day the habit was added and its earliest check-off. Past 7 and Past 30 days count every due day in the window. Was: no range started before the habit was added.

### Unchanged

B.5 THE SYSTEM SHALL CONTINUE TO judge each past day by the schedule in force on it, and to never count a future check-off.
