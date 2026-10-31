---
name: Select a day
task: T-022
status: Approved
last updated: 2026-10-30
---

# Spec: Select a Day

## 1. Summary

Clicking a day in the calendar selects it, and the habit list shows that day: the habits due then, and whether each was done. On a past day the done buttons check habits off for that day, so fixing a missed day no longer means finding its square in the strip. Today keeps a light marker while another day is selected, so it's always easy to find. The customer asked for this on 2026-10-30 (items 6 and 7) and confirmed that done buttons check off the selected past day.

## 3. Not Doing

- Checking off future days. A selected future day shows its habits, read-only.
- Streak counts for the selected day. Streaks always count up to today (T-004).
- Moving the strip's ring. It keeps marking today.
- Remembering the selection across popover opens. Every open starts on today (T-002 B.4).
- Esc clearing the selection. Esc still closes the popover from the list.

## 4. Current Behavior

- Days in the grid can't be clicked. Today has a solid accent-colored rounded square (T-013).
- The habit list always shows today: the habits due today, today's done buttons, and the folded "N not due today" row (T-012).
- Past days can be fixed only from the strip (T-003 B.5).

## 5. UI

- **Selected day:** the solid accent-colored rounded square with a white number, as today has now.
- **Today, when another day is selected:** a pale square (the accent color at about 20% opacity) with the number in the accent color, bold.
- **Hover:** a day under the pointer gets the soft hover highlight (T-021).
- **Habits header:** unchanged, "HABITS", whatever day is selected (the customer, 2026-10-30: the date isn't needed there; the calendar's solid square shows the selected day).
- **Done buttons on a selected past day:** as today's, but their tooltips and spoken labels name the day: "Mark done for Oct 23", "Push-ups, done on October 23".
- **Done buttons on a selected future day:** shown dimmed and can't be clicked; the tooltip is "Can't check off a future day".
- **Folded row:** "N not due today" on today; "N not due that day" on another day.
- **"Nothing due today"** reads "Nothing due that day" on another day.

## 7. Behavior

### New

B.1 WHEN the user clicks a day in the grid THE SYSTEM SHALL select it and show the habit list for it. Clicking a faint day from the next or previous month also pages to that month.

B.2 WHILE a day other than today is selected THE SYSTEM SHALL mark today with the pale square, and the selected day with the solid one.

B.3 WHILE a day is selected THE SYSTEM SHALL list the habits due that day, and fold the others into the "not due" row (T-012's rules, for the selected day).

B.4 WHEN the user clicks a done button for a selected day on or before today THE SYSTEM SHALL toggle that habit's check-off for that day, and update its strip and streaks immediately.

B.5 WHILE the selected day is after today THE SYSTEM SHALL show its due habits with done buttons that can't be clicked.

B.6 WHEN the user clicks the Today button THE SYSTEM SHALL select today and show its month.

B.7 WHEN the popover opens THE SYSTEM SHALL select today.

B.8 WHILE today is selected and the day changes at midnight THE SYSTEM SHALL select the new today. A different selected day stays selected.

B.9 Spoken labels: a grid day reads as now ("Thursday, October 29, 2026, today"), adding ", selected" when selected; done buttons name the day as in §5.

### Unchanged

B.10 THE SYSTEM SHALL CONTINUE TO allow fixing past days from the strip, and to count streaks up to today.
