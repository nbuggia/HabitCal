---
task: T-021
rigor: Simple
status: Approved
date created: 2026-10-30
---

# Tech Design: Hover and Pressed States

## Summary

One `ButtonStyle`, `HoverButtonStyle` (`.hover`, `.hover(cornerRadius:outset:overLabel:)`), replaces `.borderless` and `.plain` on every popover button. It tracks hover with `onHover`, reads `isPressed` and `isEnabled`, and draws the highlight behind the label, or over it for filled labels.

## Approach

- `HabitCal/Views/HoverButtonStyle.swift`: the style and its body view (hover is `@State` in the body, since a style can't hold state).
- Apply it in `CalendarView` (navigation), `HabitListScreen` (header buttons, folded row), `HabitRow` (name, done button), `SettingsScreen` (Back, Quit), `HabitFormScreen` (Cancel, Add/Save, day circles, Delete habit), and `LeaderboardScreen` (Back, range tabs).
- The form's day buttons: the label becomes the 26 pt circle itself, with the button centered in its column, so the circular highlight matches. The clickable area is unchanged: it was already the circle (`contentShape(Circle())`).
- Plain and custom styles don't dim when disabled the way borderless did, so the style dims to 40%.

## Test Points

| Test (named for the behavior it proves) | Kind (unit / integration / UI / manual) | Spec rules proved |
| --- | --- | --- |
| Existing UI suite: every button still found by label and still works | UI (next full run) | B.3 |
| `testUnreadableDataShowsMessageAndDisablesAdd` | UI (next full run) | B.2 |
| Hover and press each kind of button, light and dark | manual: docs/manual-tests/habits.md | B.1, B.2 |

## Lasting Changes

| Change | Goes to |
| --- | --- |
| Popover buttons use `.hover` | docs/engineering/CONVENTIONS.md, Popover |
