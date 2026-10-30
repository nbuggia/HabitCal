---
task: T-006
rigor: Simple
status: Approved
date created: 2026-10-30
---

# Tech Design: Calendar Polish

## Summary

The grid's `GridItem(.flexible())` columns become `.fixed(32)` with 2 pt spacing, and the grid is centered in the popover. It's a layout change in one view. Simple rather than Trivial, because it's a change users see, made through the task's spec.

## Approach

- `HabitCal/Views/CalendarView.swift`: change `columns`; the `LazyVGrid` gets `spacing: 0` between rows and a centered frame. `DayCell`'s `.frame(maxWidth: .infinity, minHeight: 24)` becomes a fixed 32 × 24.

## Test Points

| Test (named for the behavior it proves) | Kind (unit / integration / UI / manual) | Spec rules proved |
| --- | --- | --- |
| Existing calendar UI tests stay green | UI | B.2 |
| Screenshot of the calendar: days closer, grid centered | manual (screenshot, shown to the customer) | B.1 |

## Lasting Changes

None.
