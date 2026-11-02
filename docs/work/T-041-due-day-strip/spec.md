---
name: Due-day strip
task: T-041
status: Approved
last updated: 2026-11-01
---

# Spec: Due-Day Strip

## 1. Summary

Each habit's strip shows its last 30 due days, oldest on the left and newest on the right, ending at the day shown in the list (today, or the day selected in the calendar), which is marked. Days the habit isn't due don't appear, so a Monday/Wednesday/Friday habit shows only Mondays, Wednesdays, and Fridays. The strip becomes a picture of how the habit has gone. Past days are fixed by selecting the day in the calendar (T-022), not by clicking the strip.

## 2. Users

- **For:** someone glancing at a habit to see how they've kept it up lately.
- **Core value:** at a glance, a habit's recent record counts only the days it was due, so a three-days-a-week habit isn't drowned in grey "not scheduled" squares.
- **Not for:** fixing days from the strip; that moves to the calendar and the done button.

## 3. Not Doing

- Clicking a dot to check it off. The customer chose a strip that isn't clickable (2026-11-01); the calendar and done button already fix any past day (T-022).
- Keyboard focus or VoiceOver on the strip. The customer chose to hide it from VoiceOver (2026-11-01): the row's done button and streak already speak for the habit.
- A different length per habit. The customer chose a fixed 30 dots (2026-11-01), so every row is the same width.
- Following the calendar's displayed month. Paging months no longer changes the strips; only the shown day does (B.8).

## 4. Current Behavior

- Each habit's strip shows one square for every day of the month displayed in the calendar, 1st on the left. Done is green, missed red, not scheduled grey, future outlined, and days past a short month's end blank — T-003 §5; `stripShowsDoneMissedNotScheduledAndFutureForTheMonth`.
- Today's square has an accent ring; days before the habit was added show as due, so they're missed or done — T-028; `stripShowsDaysBeforeAddedAsMissedOrDone`.
- Clicking a past due square toggles it; not-due and future squares do nothing — T-003 B.6; `testFixingAMissedDayInTheStrip`.
- The strip is one Tab stop: ← and → move a cursor (a heavier ring), and Space toggles its day. VoiceOver reads "Push-ups, October 2026" and the cursor's day, adjusts day by day, and toggles with its default action — T-003 E.8; `testStripIsOneTabStopThatArrowsAndSpaceDrive`; manual test habits.md, "VoiceOver adjusts the strip day by day".
- Each square has a hover tooltip ("Oct 5 · done") — T-003 §5.
- A day selected in the calendar shows its habits in the list, and their done buttons fix that day — T-022. The strip's ring stays on today — T-022 Not Doing.
- The list shows only habits due on the shown day — T-036.
- A day checked off counts as due even if the schedule leaves it out (merged from another Mac) — T-039 B.21.

## 5. UI

- 30 rounded squares in one row, filling the same width as the month strip today (each a little larger: 30 instead of 31). "Dots" in this spec means these squares (customer, 2026-11-01: keep the shape).
- Colors: done green, missed red, future outlined, as today. Not done before the habit was added: faint grey, the not-scheduled grey of today's strip, so it doesn't read as a failure (customer, 2026-11-01).
- The newest square, the shown day, has the accent ring today's square has now.
- Empty slots (when fewer than 30 due days exist, E.5) are blank, on the left.

## 6. Use Cases

| Use case | Journey | How to verify |
| --- | --- | --- |
| UC-1 See how a habit's going | Open the popover; each habit's strip shows its last 30 due days ending today, today marked. | Unit tests of the 30-day sequence (the strip is hidden from accessibility, B.7, so UI tests can't read it); manual look |
| UC-2 Look back from a selected day | Select a past day; the strips end at that day, marked. | Unit test; UI test checks the done button names that day; manual look |
| UC-3 Fix a missed day | Select the day in the calendar, click the habit's done button; its dot turns green. | Existing T-022 test |

## 7. Behavior

### New

B.1 THE SYSTEM SHALL show each habit's 30 most recent due days up to and including the shown day (the selected day, or today), oldest on the left and newest on the right.

B.2 THE SYSTEM SHALL count as due exactly the days the habit counts as due elsewhere: a day its schedule then in force includes, or a day that's checked off (T-039 B.21). Days it isn't due on don't appear.

B.3 THE SYSTEM SHALL mark the newest dot, the shown day, with the accent ring.
Why: a listed habit is always due on the shown day (T-036), so the newest dot is always the shown day.

B.4 WHEN the shown day is after today (a future day selected) THE SYSTEM SHALL show the due days after today as future (outlined).

B.5 THE SYSTEM SHALL keep each dot's hover tooltip ("Oct 5 · done"; "Oct 5 · before added" for a faint one).

B.5a THE SYSTEM SHALL show a due day before the habit was added as faint grey when it isn't done, and green when it is. Was: missed (red) like any due day (T-028 in the month strip). Why: with 30 due days, a weekly habit would otherwise start with months of red for days before it existed (customer, 2026-11-01). Streaks and the leaderboard don't change (B.12).

### Changed

B.6 THE SYSTEM SHALL NOT change anything when a dot is clicked. Was: a past due square toggled (T-003 B.6). Why: the customer chose a strip that isn't clickable (2026-11-01).

B.7 THE SYSTEM SHALL NOT give the strip keyboard focus, and SHALL hide it from VoiceOver. Was: one Tab stop with arrows, Space, and VoiceOver adjust (T-003 E.8). Why: customer, 2026-11-01; the calendar and done buttons fix past days by keyboard and VoiceOver (T-022).

B.8 WHEN the calendar pages to another month without a day being selected THE SYSTEM SHALL leave the strips as they are. Was: the strip showed the displayed month (T-003 §5).

B.9 THE SYSTEM SHALL show no "not scheduled" dots, and no blank ones except the empty slots of E.5. Was: grey squares for days not due, blank ones past a short month's end (T-003 §5).

B.9a THE SYSTEM SHALL put the accent ring on the shown day (the newest dot) only; when a future day is selected, today has no marker in the strip. Was: the ring stayed on today, even with another day selected (T-022 Not Doing; T-003 §5).

### Unchanged

B.10 THE SYSTEM SHALL CONTINUE TO show done, missed, and future in the same colors, and to count days before the habit was added as due. Covered by: new strip unit tests (design).

B.11 THE SYSTEM SHALL CONTINUE TO let the user fix a past day by selecting it in the calendar and using the done button. Covered by: `testSelectingAPastDayShowsAndFixesItsHabits`.

B.12 THE SYSTEM SHALL CONTINUE TO count streaks and the leaderboard as before. Covered by: `StreakTests`, `ConsistencyTests`.

### Removed

- Checking off from the strip by click, keyboard, or VoiceOver (T-003 B.6, E.8), and the strip's cursor.
- Tests that go: `testFixingAMissedDayInTheStrip`, `testStripIsOneTabStopThatArrowsAndSpaceDrive`, `testEscStillClosesAfterTheFocusedStripLeavesTheList` (the strip takes no focus). Rewritten without reading the strip: `testCheckingOffTodayFillsTheButtonAndTodaysSquare` (the button only), `testHabitControlsHaveSpokenLabels` (no strip label), `testCheckingOffUpdatesTheStreakImmediately` (fixes the 28th through the calendar). The unit tests `stripShows…` are rewritten for the new sequence.
- Manual tests: "VoiceOver adjusts the strip day by day" (habits.md) goes; "Habit rows look right in every appearance" drops "not-scheduled squares faint grey" and checks the faint before-added squares and the ring on the shown day.
- PRD and CONTEXT.md: the strip "for the month on show … or not scheduled" and "a past day fixed from the strip" are replaced (customer approved, 2026-11-01).

## 8. Limits

- Dots: always 30.

## 9. Edge Cases and Errors

E.1 WHEN a check-off changes (done button, another Mac, a new day) THE SYSTEM SHALL update the dots at once.

E.2 WHEN the schedule changes from today THE SYSTEM SHALL keep past dots on the schedule then in force (only days due then appear), and new due days follow the new schedule.

E.3 WHEN a habit is new THE SYSTEM SHALL still show 30 dots, the ones before it was added as missed (B.10, T-028).

E.4 WHEN today changes at midnight with the popover open THE SYSTEM SHALL move the strips with it, if today is the shown day.

E.5 WHEN fewer than 30 due days exist in the three years before the shown day (a merged habit whose earliest schedule has no days, T-039 B.8a; a schedule that rarely includes a day) THE SYSTEM SHALL show the ones that exist on the right and blank slots on the left. Why: the search for due days has to stop somewhere; three years is far past what 30 dots show for any weekly schedule.

## 13. Assumptions

- "Missed" for today before it's done stays as today's month strip shows it.

## Review

st-crit, 2026-11-01, CONCERNS; seven findings, all accepted. The strip is hidden from accessibility, so the use cases are verified by unit tests and manual looks, and the tests that change are listed (Removed). The PRD and CONTEXT.md are updated (customer approved). Days before a habit was added show faint, not red (customer chose, B.5a). E.5 covers fewer than 30 due days. B.9a records the ring moving off today. The manual tests that change are listed. "Dots" are the same rounded squares (customer chose).
