---
name: Due today only
task: T-012
status: Approved
last updated: 2026-10-30
---

# Spec: Due Today Only

## 1. Summary

The habit list shows only the habits due today, so the popover answers "what do I still have to do today?" at a glance. Habits not due today fold into one row at the bottom of the list, and clicking that row shows them, so they can still be edited, deleted, and fixed from their strips. The customer asked for this on 2026-10-30 ("Don't show habits that are not due today").

## 3. Not Doing

- Hiding them with no way back. A habit that's hidden all day couldn't be edited or deleted that day, and a habit added for another weekday would vanish the moment it was saved. The folded row is the agent's default, chosen while the customer was away; they can drop it.
- Remembering whether the row is open across popover opens. It starts closed every time, like the form (T-003 E.2).

## 4. Current Behavior

- Every habit has a row, in the order added. A habit not due today shows a dashed done button that can't be clicked, with the tooltip "Not scheduled today" (T-003 §5, E.8).
- The empty list says "No habits yet. Add one to start a streak."

## 5. UI

- **Due today:** the rows of habits due today, in the order added, as now.
- **Folded row**, last in the list, only when at least one habit isn't due today: a disclosure button in small secondary text, "1 not due today" or "3 not due today", with a caret that points right when closed and down when open. Clicking it shows those habits' rows under it, in the order added, looking exactly as today (dashed done button included). Clicking again hides them.
- **Nothing due today, but some habits exist:** in place of the due rows, "Nothing due today" in secondary text, then the folded row.
- **No habits at all:** unchanged, "No habits yet. Add one to start a streak."

## 7. Behavior

### Changed

B.1 WHEN the popover shows the habit list THE SYSTEM SHALL show a row for each habit due today and SHALL NOT show rows for habits not due today until the user opens the folded row. Was: every habit had a row. Why: the customer wants the list to be today's to-do list.

B.2 WHEN at least one habit isn't due today THE SYSTEM SHALL show a folded row at the bottom of the list, labeled "N not due today", which shows and hides those habits' rows when clicked. It SHALL start closed each time the popover opens. Spoken label: "3 habits not due today", with the value "collapsed" or "expanded".

B.3 WHEN habits exist and none is due today THE SYSTEM SHALL show "Nothing due today" above the folded row.

B.4 WHEN the user saves a habit, new or edited, that isn't due today THE SYSTEM SHALL open the folded row, so the habit they just saved is listed. With a list taller than the popover it may sit below the scroll; the list doesn't scroll to it.

B.5 WHEN the day changes while the popover is open THE SYSTEM SHALL move habits between the list and the folded row to match the new day.

### Unchanged

B.6 THE SYSTEM SHALL CONTINUE TO show the dashed done button, strip, streaks, and edit controls on a not-due habit's row once it's shown, and to allow fixing past days from its strip (T-003 B.5).

B.7 THE SYSTEM SHALL CONTINUE TO show "No habits yet. Add one to start a streak." when there are no habits.

### Narrowed

B.8 With the Mac's Keyboard navigation setting off, the folded row isn't a Tab stop, so a folded habit's strip can't be reached from the keyboard until the row is opened with the mouse. Was: every strip was a Tab stop either way (T-003 E.8). Why: the folded row is a button, and buttons follow the Mac's setting (the platform norm); with the setting on, Tab reaches it and Space opens it.
