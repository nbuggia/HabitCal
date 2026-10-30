---
name: Habits
task: T-003
status: Approved
last updated: 2026-10-29
---

# Spec: Habits

## 1. Summary

Habits live in the popover under the month calendar (T-002). Each habit has a name, a schedule of weekdays, and optional notes. Each row has a done button for today and a strip showing the displayed month: done, missed, or not scheduled. Clicking a square in the strip fixes a past day. Adding, editing, and deleting happen in a form inside the popover. Everything stays on this Mac.

## 2. Users

- **For:** someone building a few recurring habits, some daily and some on particular weekdays, who wants to check them off from the menu bar.
- **Core value:** checking off today's habit is one click from the menu bar, and that check-off survives quitting, relaunching, and restarting.
- **Not for:** people tracking counts or durations, or wanting reminders, sync, or a social feed (PRD Not Doing).

## 3. Not Doing

- Counted or timed goals ("50 push-ups"). A habit is done or not done for the day (PRD Not Doing).
- Reminders and notifications. HabitCal is glanceable, not a nag (PRD Not Doing).
- Sync, accounts, or sending any data off the Mac (PRD Not Doing).
- Habit categories, icons, or journaling. The list stays short and flat. The prototype's sample data had icons, but rows don't show them and the form can't set them.
- Habit limits or paywalls. The app is free with no ceiling (PRD Not Doing).
- Checking off a future day. The strip only allows today and earlier.

## 4. Current Behavior

New feature; nothing exists today.

## 5. UI

From the T-001 prototype ("Final" card and its screens).

**Habit list** (below the calendar, after a separator):

- A "Habits" section label.
- One row per habit, in the order they were added. Each row has a top line and a strip.
  - **Top line:**
    1. The **done button**, a 24 pt circle. Its states:
       - due today and not done: an empty outlined circle, with the tooltip "Mark done today";
       - done today: filled green with a white check, with the tooltip "Done today — click to undo";
       - not due today: a dashed circle that can't be clicked, with the tooltip "Not scheduled today".
    2. The **name**, in semibold. A pencil appears beside it on hover, and the tooltip is "Edit habit". The **schedule label** sits under the name in small text.
    3. On the right, the two streak counts from T-004.
  - **Strip:** 31 small squares in one row, one per day of the displayed month, aligned under the name. In a month shorter than 31 days, the extra squares are blank.
- **Empty list:** "No habits yet. Add one to start a streak."
- **Footer:** "+ Add habit" and the Settings gear (T-002).

**Strip square states:**

| Day | Look | Tooltip |
| --- | --- | --- |
| Past or today, due, done | Solid green | "Oct 5 · done" |
| Past, due, not done | Soft red | "Oct 5 · missed" |
| Today, due, not done yet | Soft red, like missed | "Oct 29 · missed" |
| Not due (any day) | Faint grey | "Oct 4 · not scheduled" |
| Future, due | Empty, outlined | "Oct 30" |
| Future, not due | Empty, fainter outline | "Oct 31 · not scheduled" |

Today's square also has an accent-colored outline.

**Schedule label:** "Every day" for all seven days, "Weekdays" for Monday to Friday, and "Weekends" for Saturday and Sunday. Otherwise it lists the short day names Monday-first, separated by commas: "Mon, Wed, Fri" or "Fri, Sun".

**Habit form.** It replaces the list inside the popover; one form serves both Add and Edit. From top to bottom:

1. **Header:** "Cancel" on the left; the title "New habit" or "Edit habit" in the middle; "Add" or "Save" on the right.
2. **Name:** a text field with the placeholder "e.g. Push-ups".
3. **Repeats on:** seven toggle buttons showing day initials, in week-start order (T-002 B.15). Each has the full day name as its tooltip.
4. **Notes:** a three-line text area with the placeholder "Optional details, e.g. 3 sets of 20, or the route you run".
5. **Hints,** below the form, when they apply:
   - with no days picked: "Pick at least one day."
   - when editing and the schedule has changed: "The new schedule starts today. Past days, and your streak, keep the old one."
6. **Edit only:** a separator, then a red "Delete habit" button with a trash icon. Clicking it replaces the button with a confirmation:
   - "Delete “‹name›”?"
   - "Its history and streaks are deleted too. This can't be undone."
   - Two buttons: Cancel, and a red Delete.

**Right-click menu on a row:** "Edit…" and "Delete…", with a separator between them.

## 6. Use Cases

| Use case | Journey | How to verify |
| --- | --- | --- |
| UC-1 Add a habit | "+ Add habit", type "Run", pick Fri and Sun, add a note, then Add. The row appears with the label "Fri, Sun". | UI test |
| UC-2 Check off today | Click the done button; it fills green and today's square turns green. Click again to undo. | UI test |
| UC-3 Fix a missed day | Click a red square for an earlier day; it turns green. Page back a month to fix a day there. | UI test |
| UC-4 Edit a habit | Click the name (or right-click › Edit…), rename it, change its days, then Save. | UI test |
| UC-5 Delete a habit | Right-click › Delete…, then confirm. The row and its history are gone. | UI test |
| UC-6 Data survives | Check off habits, quit, and relaunch (and restart the Mac); everything is as it was. | Integration test, plus a manual restart |

## 7. Behavior

### New

**Schedules and due days**

B.1 A habit is due on a day WHEN that day's weekday is in the schedule in force for that day, and the day is on or after the habit was added.

B.2 WHEN a habit's schedule changes THE SYSTEM SHALL apply the new schedule from today onward. Days before today keep the schedule that was in force on them.
Why: changing "Fri, Sun" to "Mon, Wed, Fri" shouldn't turn last month's Sundays into "not scheduled" or create retroactive misses.

B.3 WHEN the schedule changes more than once on the same day THE SYSTEM SHALL keep only the last change for that day.

**Checking off**

B.4 WHEN the user clicks the done button of a habit due today THE SYSTEM SHALL mark today done. A click always marks the day the row is showing, even if midnight has just passed and the row hasn't updated yet. WHEN it is already done THE SYSTEM SHALL unmark it. The button, today's square, and the streaks (T-004) update immediately.

B.5 WHEN the user clicks a strip square for a day that is today or earlier and on which the habit is due THE SYSTEM SHALL toggle that day between done and not done.

B.6 WHEN the user clicks a square for a future day or a day the habit isn't due THE SYSTEM SHALL do nothing.

B.7 THE SYSTEM SHALL show each habit's strip for the month displayed in the calendar, so paging months (T-002) pages every strip together.

**Adding and editing**

B.8 WHEN the user clicks "+ Add habit" THE SYSTEM SHALL open the form empty, with all seven days selected and the cursor in Name.

B.9 WHEN the user clicks a habit's name, or chooses Edit… from its right-click menu, THE SYSTEM SHALL open the form filled with that habit's name, days, and notes, with the name selected.

B.10 THE SYSTEM SHALL enable Add or Save only WHILE the name has a non-space character and at least one day is selected.

B.11 WHEN the user clicks Add or Save, or presses Return in the Name field, while it is enabled THE SYSTEM SHALL save the habit, with leading and trailing spaces trimmed from the name and notes, and return to the list. A new habit goes to the bottom of the list.

B.12 WHEN the user clicks Cancel or presses Esc in the form THE SYSTEM SHALL return to the list without saving.

B.13 WHEN a habit is saved with a schedule that no longer includes today, and today was marked done, THE SYSTEM SHALL remove today's check-off.
Why: today is judged by the new schedule (B.2), and a check-off on a day that isn't due would count nowhere.

B.14 THE SYSTEM SHALL allow two habits with the same name.

**Deleting**

B.15 WHEN the user clicks "Delete habit" THE SYSTEM SHALL show the confirmation. Choosing Delete… from the right-click menu opens the Edit form with the confirmation already showing.

B.16 WHEN the user confirms THE SYSTEM SHALL delete the habit, its schedule history, and all its check-offs, and return to the list. Cancel hides the confirmation and leaves the form open.

**Right-click menu**

B.17 WHEN the user right-clicks a habit row THE SYSTEM SHALL show the Edit… / Delete… menu at the pointer, and close it on a choice, a click elsewhere, or Esc.

**Saving and privacy**

B.18 WHEN the user checks off a habit, fixes a day, or adds, edits, or deletes a habit THE SYSTEM SHALL save the change to this Mac at once. Habits and history survive quitting, relaunching, crashing, restarting the Mac, and updating HabitCal to a newer version.

B.19 A check-off belongs to the local calendar date it was made for, and SHALL NOT move to another date when the Mac's time zone changes.
Why: a habit done on October 5 in New York was done on October 5. Time zone math must not shift it to the 4th or 6th.

B.20 THE SYSTEM SHALL keep all habit data on this Mac and SHALL NOT make any network request.
Why: the app works offline, needs no account, and sends no data anywhere (PRD Done Means).

## 8. Limits

- Habit name: 1–40 characters after trimming.
- Notes: 0–280 characters.
- Days per schedule: 1–7.
- Number of habits: no limit (PRD Not Doing: no habit limits).
- Strip: 31 squares; blanks after the month's last day.

## 9. Edge Cases and Errors

E.1 WHEN there are more habits than fit on screen THE SYSTEM SHALL let the habit list scroll while the calendar and footer stay in place, so the popover never runs off the screen.

E.2 WHEN the popover closes while the form is open THE SYSTEM SHALL discard the unsaved form. The next open shows the list (T-002 B.4).

E.3 WHEN the date changes while the popover is open THE SYSTEM SHALL update each done button and today's square to the new day within one minute, the same limit as the icon (T-002 B.2).

E.4 WHEN the user types or pastes past 40 characters in Name or 280 in Notes THE SYSTEM SHALL stop at the limit.

E.5 WHEN the saved data can't be read at launch THE SYSTEM SHALL NOT overwrite it, and SHALL show "HabitCal couldn't read your habits" in the popover in place of the list, with the data file's location.
While the data can't be read, "+ Add habit" SHALL be disabled and nothing SHALL be saved. The calendar and Settings still work.
Why: an empty list that then saves over unreadable data would destroy the user's whole history.

E.6 WHEN a change can't be saved THE SYSTEM SHALL keep it on screen and show "Couldn't save — your last change may be lost" at the top of the habit list until a later save succeeds.

E.7 WHEN the Mac's clock moves backward past days that have check-offs THE SYSTEM SHALL keep those check-offs, and show and count them only once those days arrive again.

E.8 Keyboard and VoiceOver: every done button, name, form control, and menu item SHALL be reachable with Tab. Each strip is a single Tab stop: the arrow keys move between days, and Space toggles a day that B.5 allows. Spoken labels: "Push-ups, done today", "Push-ups, not done today", or "Push-ups, not scheduled today"; "October 5, done" (or missed, or not scheduled); and "Edit Push-ups". Space also toggles the focused done button.
Why: a Tab stop per square would mean 31 stops per habit.

E.9 WHEN the week start changes (T-002 B.13) while the form is open THE SYSTEM SHALL reorder the day buttons and keep the selected days.

## 10. Contracts

- **Saved habit data:** private to HabitCal, but every later version of HabitCal reads it. The data carries a format version. Every newer HabitCal reads every earlier format. A HabitCal that finds a format newer than it knows treats the data as unreadable (E.5) and never overwrites it, so downgrading can't destroy history.

## 11. Success Criteria

- A new habit with a schedule can be added in under 30 seconds (PRD Done Means).
- Checking off today's habit is one click once the popover is open (PRD Done Means).

## 12. Deferred

- Reordering habits by drag — not in the prototype; creation order is enough for a short list.
- Showing notes anywhere but the form, such as in a tooltip on the row.
- Undo for delete — the confirmation is the safeguard for v1.
- Export and backup of habit history — already in BACKLOG.md.

## 13. Assumptions

- Closing the popover discards an unfinished form (E.2), matching how other menu bar popovers behave.
- Today's square looks missed until checked off. The prototype does this, and the done button already makes "not yet" clear.
- A habit added today is due today if today is in its schedule, so it can be checked off right away.
