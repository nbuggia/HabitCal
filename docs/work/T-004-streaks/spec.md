---
name: Streaks
task: T-004
status: Approved
last updated: 2026-10-29
---

# Spec: Streaks

## 1. Summary

Each habit row shows two numbers: the current streak (🔥) and the best streak ever (🏆). Both count only the days the habit was due, so a run on Fridays and Sundays keeps its streak through the week in between. Today never breaks a streak while it's still today.

## 2. Users

- **For:** someone with habits on different schedules who wants to see momentum and not break the chain.
- **Core value:** the streak is fair. A day the habit wasn't due never breaks it, and fixing a missed day restores it right away.
- **Not for:** anyone who wants skip days, "N times per week" goals, or streak rewards. Those are in the backlog or out of scope.

## 3. Not Doing

- Excused or skipped days that don't break a streak. Already in BACKLOG.md as "Skip / excused days".
- A day-rollover hour for late nights. Already in BACKLOG.md.
- Badges, milestones, or celebrations. Category reviews fault busy, gamified interfaces (PRD Appendix).

## 4. Current Behavior

New feature; nothing exists today. Due days, check-offs, and schedule changes come from T-003.

## 5. UI

At the right of each habit's top line (T-003):

- **Current streak:** a fire icon and the number, with the tooltip "Current streak". At 3 or more, the icon and number turn flame-orange and the number is semibold. Below 3, they stay in the normal secondary color.
- **Best streak:** a trophy icon and the number, with the tooltip "Best streak".
- A habit with no completed due days shows 0 for both.

## 6. Use Cases

| Use case | Journey | How to verify |
| --- | --- | --- |
| UC-1 See momentum | Open the popover; each habit shows its current and best streak. | UI test |
| UC-2 Scheduled gap | A Fri/Sun habit done on Friday and Sunday shows 2 on the Wednesday between, then 3 after the next Friday. | Unit tests of the rules below |
| UC-3 Fix a miss | Check off a missed day in the strip; the current and best streaks recompute right away. | UI test |

## 7. Behavior

### New

B.1 THE SYSTEM SHALL compute a habit's current streak by walking back from today through its due days only (T-003 B.1). It counts each done day and stops at the first due day before today that wasn't done.

B.2 WHEN today is due and not yet done THE SYSTEM SHALL skip today, without counting it or stopping, so the streak shows the run up to yesterday.
Why: the day isn't over. A streak that drops to 0 every morning would punish the user for opening the app early.

B.3 THE SYSTEM SHALL compute the best streak as the longest unbroken run of done due days in the habit's whole history, including the current streak. A due day that wasn't done breaks a run; today, before it's done, doesn't.

B.4 THE SYSTEM SHALL judge each past day by the schedule in force on that day (T-003 B.2). A streak runs unbroken across a schedule change if the due days on both sides were done.

B.5 THE SYSTEM SHALL ignore days before the habit was added, and check-offs on future days (T-003 E.7).

B.6 WHEN a check-off is added or removed, on any day, or a habit's schedule changes THE SYSTEM SHALL recompute both streaks immediately.

Examples. The habit is due Fri and Sun; ✓ means done, ✗ means missed:

| History (oldest → today) | Current | Best |
| --- | --- | --- |
| Fri ✓, Sun ✓, today Wed (not due) | 2 | 2 |
| Fri ✓, Sun ✓, today Fri (due, not done yet) | 2 | 2 |
| Fri ✓, Sun ✓, today Fri ✓ | 3 | 3 |
| Fri ✓, Sun ✓, Fri ✓, Sun ✗, today Fri ✓ | 1 | 3 |
| Fri ✓, Sun ✗, today Wed | 0 | 1 |
| Added today (Wed), not due today | 0 | 0 |

## 8. Limits

- "Hot" threshold: a current streak of 3 or more is shown in flame-orange.
- Streaks have no upper limit, and the numbers are never abbreviated. A habit done every day for years shows "1095".

## 9. Edge Cases and Errors

E.1 WHEN a habit's schedule changes so that today is no longer due THE SYSTEM SHALL recompute the streaks without today (T-003 B.13).

E.2 WHEN the date changes while the popover is open THE SYSTEM SHALL recompute the streaks for the new today. This is when yesterday's undone due day starts breaking the current streak.

E.3 WHEN a habit is deleted THE SYSTEM SHALL delete its streaks with it. There is nothing to recompute.

E.4 VoiceOver SHALL read the streaks as "Current streak 12 days, best streak 30 days", with "day" for 1.
