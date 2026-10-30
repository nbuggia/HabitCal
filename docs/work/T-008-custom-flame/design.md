---
task: T-008
rigor: Simple
status: Approved
date created: 2026-10-30
---

# Tech Design: Custom Flame

## Summary

The flame is drawn once, in `docs/artwork/flame.svg`. `make-flame-pdf.swift` converts it to `flame.pdf` in the asset catalog, and `HabitRow`'s `StreakStats` shows `Image("flame")`: full color when hot, `.saturation(0).opacity(0.55)` otherwise. `render-app-icon.swift` draws the SVG into the icon. Phosphor's `ph-fire` asset is removed.

## Approach

- An SVG with gradients in the asset catalog stalled the popover whenever a habit row was on screen (proven: swapping in a system image fixed it). A PDF made from the same SVG works. So the SVG is the source, and the PDF is generated from it.

## Test Points

| Test (named for the behavior it proves) | Kind (unit / integration / UI / manual) | Spec rules proved |
| --- | --- | --- |
| `testCheckingOffUpdatesTheStreakImmediately` and the full UI suite (the popover opens with habits on screen) | UI | B.1, B.3 |
| Screenshot of hot and grey flames in rows; icon renders | manual | B.1, B.2 |

## Lasting Changes

| Change | Goes to |
| --- | --- |
| The flame is HabitCal's own drawing; source SVG, shipped PDF, and why | docs/artwork/README.md; ARCHITECTURE.md assets note |
| Asset catalogs: ship vectors with gradients as PDF, not SVG | COMMON-FAILURE-MODES.md (FM-011) |
| Streak flame is no longer Phosphor (amends D-008's "Phosphor for in-app icons") | DECISIONS.md: proposed to the customer |
