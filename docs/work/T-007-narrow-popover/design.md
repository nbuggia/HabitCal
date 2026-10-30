---
task: T-007
rigor: Simple
status: Approved
date created: 2026-10-30
---

# Tech Design: Narrow Popover

## Summary

`PopoverRoot`'s `.frame(width: 330)` becomes a named constant, `PopoverRoot.width = 280`. `StripView`'s square spacing goes from 2 to 1.5. These are layout values only.

## Approach

- `HabitCal/Views/PopoverRoot.swift`: `static let width: CGFloat = 280`, used in `.frame`.
- `HabitCal/Views/StripView.swift`: `HStack(spacing: 1.5)`.
- Check the list, the form, and Settings by screenshot for clipping. Settings' "Week starts on" row is the tightest, with a label and a segmented control.

## Test Points

| Test (named for the behavior it proves) | Kind (unit / integration / UI / manual) | Spec rules proved |
| --- | --- | --- |
| Full UI suite stays green | UI | B.3 |
| Screenshots of list, form, and Settings at 280 pt | manual (shown to the customer) | B.1, B.2, B.3 |

## Lasting Changes

| Change | Goes to |
| --- | --- |
| Popover width is `PopoverRoot.width` (280 pt) | ARCHITECTURE.md, The Popover |
