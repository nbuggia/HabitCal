# Prototype: menu bar concepts

## Question

What should HabitCal look like in the menu bar and its popover, so that checking the date and checking off today's habits both take one glance and one click? Five options, side by side, in light and dark mode: `index.html`.

1. **Classic** — date as text; month with a dot per day; today's checklist below.
2. **Progress Ring** — ring around the date fills as habits are done; per-day rings in the month.
3. **Habit Rows** — compact month plus one heatmap strip per habit.
4. **Streak First** — longest live streak in the menu bar; one habit at a time with its own calendar.
5. **Quiet Calendar** — calendar icon only; month shaded by completion; click a day to edit it.

## Answer

**Menu bar icon — locked (2026-10-29):** Concept 5's calendar-page icon, revised by the customer: the month abbreviation (OCT) cut out of a solid header bar like an old tear-off calendar, the day number below. All four corners rounded. No progress indicator: the customer tried an outline ring, then a line along the top and the bottom, and removed it to keep the icon calm. See the "Menu bar icon" section at the top of `index.html`.

**Popover — in progress (2026-10-29):** the customer chose Concept 3 (Habit Rows), with Phosphor icons (https://phosphoricons.com, MIT). The "Final" card in `index.html` merges it with the locked icon and adds a tick button per habit for today.

**Concepts removed (2026-10-29):** the five original concepts were deleted from `index.html` once the customer chose the direction. The page now holds the locked icon, the live Final popover, and static snapshots of its screens.

**Popover screens so far:** the habit list (done button leading each row, streaks on the right, monthly strip); the habit form for Add and Edit (name, repeats-on day buttons, optional notes, delete with confirmation; a schedule change applies from today); and Settings (Launch at login, Week starts on Sunday/Monday, About line, Quit).

**Settings, revised (2026-10-29):** the app name ("HabitCal 1.0") and website (www.muchfiner.com) sit at the top of Settings; Quit stays at the bottom.

## Requirements to carry into the v1 spec

Rules the customer set while prototyping. They belong in the spec's Behavior section when T-001's spec is written.

- **Week start follows the Mac, until the user overrides it.**
  - On first launch, the first day of the week SHALL match the Mac's setting (System Settings › General › Language & Region › First day of week).
  - While the user hasn't chosen one, it SHALL keep following the Mac, including if the Mac's setting changes later.
  - The user SHALL be able to override it with Sunday or Monday in Settings. The override applies to the month calendar and the order of the habit form's day buttons, and persists across relaunches.
  - Settings SHALL show which day the Mac uses while an override is on, and offer "Use Mac setting" to go back to following it.

**Renamed (2026-10-29):** the app is now **HabitCal**, which names both jobs plainly. It was briefly CalAccrue (D-001). The project folder is `HabitCal`. See D-002.
