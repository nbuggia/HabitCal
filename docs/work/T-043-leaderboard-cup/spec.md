# Spec: Leaderboard cup (T-043)

Customer, 2026-11-24.

## Rule as it was
A leaderboard row shows a gold cup in its shield when every due day in the range so far is done (the 2026-11-13 rule). Every other row shows its rank.

## Rule as it becomes
- R1. A row SHALL show the gold cup when either:
  - (a) the habit is on its own best streak: the current streak is above 1 and at or above its best, the same test that colors the trophy on the habit list (T-025); or
  - (b) every due day in the range so far is done (today counts once it's done), with at least one due day.
- R2. Otherwise the row SHALL show its rank number.
- R3. The cup's tooltip SHALL say which condition earned it: "Every due day done", "On its best streak", or both.
- R4. Ranking, percentages, and the score SHALL CONTINUE TO work as before.

## Not doing
- Comparing streaks across habits (the customer chose each habit's own best).
- Counting days still ahead in the range.
