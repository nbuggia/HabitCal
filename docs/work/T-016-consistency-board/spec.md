---
name: Consistency board
task: T-016
status: Approved
last updated: 2026-10-30
---

# Spec: Consistency Board

## 1. Summary

A leaderboard that ranks your habits by how consistently you do them: the share of each habit's due days you checked off, over the past 7 days, the past 30 days, or all time. Ranking by share, not count, lets a habit due twice a week compete fairly with a daily one. An overall score at the top covers every habit. The customer picked this from the T-015 prototype (option 2) on 2026-10-30, with the range tabs renamed.

## 3. Not Doing

- The Streak Board and This Week options from the prototype.
- Calendar weeks and months. The ranges are rolling windows ending today.
- Remembering the chosen range across popover opens. Every open starts from the list (T-002 B.4), and the board opens on Past 7 days.

## 4. Current Behavior

- No leaderboard. Each habit row shows its current and best streak (T-004).

## 5. UI

From the T-015 prototype, option 2.

- **Entry:** a trophy button (Phosphor `trophy`) in the Habits header row, just left of Settings. Tooltip and spoken label: "Leaderboard". Disabled while the habit data can't be read, like Add.
- **Header:** "Back" on the left, "Leaderboard" centered, like Settings.
- **Range tabs:** three equal tabs filling the width: "Past 7 days", "Past 30 days", "All time". The selected one is filled with the accent color. Opens on Past 7 days.
- **Overall score card:** a large percentage, with "of due days done across all habits" beside it.
- **Rows,** one per habit, best first: the rank (a gold trophy for first place, then 2, 3, …), the name in semibold, a thin bar under the name filled to the share, and the percentage on the right.
- **No due days in range** (a habit added today that isn't due today): "—" in place of the percentage and an empty bar, ranked last.
- **No habits:** the card shows "—" and "No habits yet."; no rows.
- **Habits, but nothing due yet** (a new user's first day, before checking anything off): the card shows "—" and "No due days yet."

## 7. Behavior

### New

B.1 THE SYSTEM SHALL compute a habit's consistency over a range as the number of its due days in the range that are checked off, divided by the number of its due days in the range.

B.2 THE SYSTEM SHALL define the ranges as rolling windows ending today: Past 7 days is today and the 6 days before it; Past 30 days is today and the 29 days before it; All time starts the day the habit was added. Days before a habit was added are never due (T-003).

B.3 WHILE today is not checked off THE SYSTEM SHALL leave today out of the range's due days, so a habit not yet done today isn't marked down before the day is over (the same rule as streaks, T-004). Once checked off, today counts as a done due day.

B.4 THE SYSTEM SHALL rank habits by consistency, highest first; ties keep the order the habits were added; habits with no due days in the range come last.

B.5 THE SYSTEM SHALL show the overall score as all habits' done due days in the range divided by all their due days in the range, rounded to a whole percent. Percentages round to the nearest whole number, except that 100% means a perfect record and 0% means nothing done: a share just under 100% shows 99%, and one just over 0% shows 1%.

B.6 WHEN the user clicks the trophy button THE SYSTEM SHALL show the leaderboard on Past 7 days. WHEN the user clicks Back or presses Esc THE SYSTEM SHALL return to the habit list, on the month it was showing.

B.7 WHEN the user picks a range THE SYSTEM SHALL recompute the score, the percentages, and the order immediately.

B.8 Spoken labels: each row reads "1st, Read, 93 percent" (or "no due days"), and the score reads "74 percent of due days done across all habits".

### Unchanged

B.9 THE SYSTEM SHALL CONTINUE TO reset the popover to the habit list and the current month on every open (T-002 B.4).
