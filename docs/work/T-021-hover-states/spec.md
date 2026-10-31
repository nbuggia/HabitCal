---
name: Hover and pressed states
task: T-021
status: Approved
last updated: 2026-10-30
---

# Spec: Hover and Pressed States

## 1. Summary

Every button in the popover answers the pointer: a soft highlight on hover and a darker one while pressed, so the app feels responsive (the customer's item 5, 2026-10-30).

## 3. Not Doing

- Links (the website in Settings, "Use Mac setting", the Login Items link): they keep the system link style.
- System controls (the Launch at login switch, the Sunday/Monday control, the form's text fields, the delete confirmation's Cancel and Delete): they already have system states.

## 4. Current Behavior

- Icon and text buttons use the borderless or plain style, which shows nothing on hover and almost nothing on press. Only the habit name shows a pencil on hover.

## 5. UI

- Highlight: the text color at 8% opacity on hover and 16% while pressed, in a rounded rectangle with 5 pt corners. Disabled buttons dim to 40% and don't highlight.
- Icon buttons (calendar arrows and Today; the Habits header's +, trophy, and Settings): the highlight fills their 22 pt target.
- Text buttons (Back, Cancel, Add/Save, Quit, the habit name, "N not due today"): the highlight reaches 3–4 pt past the text, so the text doesn't move.
- Filled buttons (the done button, the form's day circles, Delete habit, the leaderboard's tabs): the highlight is drawn over the button in its own shape (a circle for the round ones).

## 7. Behavior

### New

B.1 WHILE the pointer is over an enabled button in the popover THE SYSTEM SHALL show the hover highlight; WHILE it is pressed, the pressed highlight.

B.2 WHILE a button is disabled THE SYSTEM SHALL dim it and SHALL NOT highlight it.

### Unchanged

B.3 THE SYSTEM SHALL CONTINUE TO run each button's action, spoken label, tooltip, and keyboard shortcut as before.
