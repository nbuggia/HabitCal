# Close: T-008 Custom flame

| Item | Landed in |
| --- | --- |
| B.1 HabitCal's flame beside the current streak; full color at 3+, grey below | `StreakStats` in HabitRow.swift; test `testCheckingOffUpdatesTheStreakImmediately`; screenshot |
| B.2 same flame in the app icon | docs/artwork/render-app-icon.swift reads docs/artwork/flame.svg |
| B.3 number color, tooltip, spoken label unchanged | Tests `testCheckingOffUpdatesTheStreakImmediately`, `streakSpokenLabelUsesDayAndDays` |
| Source SVG, shipped PDF, and how to regenerate | docs/artwork/README.md, "Flame"; comment in flame.svg |
| Trap: SVG gradients in the asset catalog stall the UI | FM-011 |
| Streak flame no longer Phosphor (amends D-008) | DECISIONS.md: proposed, awaiting the customer's approval |
