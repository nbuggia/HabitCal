# HabitCal

## Vocabulary

| Term | Meaning | Aliases to avoid |
| --- | --- | --- |
| Habit | Something the user wants to do on certain days of the week, tracked as done or not done each day it's due. Has a name, a schedule, and an optional note. | Task, goal, routine |
| Schedule | The days of the week a habit repeats on. A change applies from today; past days keep the schedule that was in force then. | Frequency, recurrence |
| Due day | A day the habit's schedule includes, on or after the habit was added. Only due days count toward a streak. | Scheduled day, active day |
| Check-off | Marking a habit done on a due day, either today or a past day fixed from the strip. | Completion, log, entry |
| Streak | The current streak is the unbroken run of done due days up to today, and today doesn't break it until it's over. The best streak is the longest such run ever. | Chain, run (in the UI) |
| Strip | The row of squares under a habit showing each day of the displayed month: done, missed, or not scheduled. | Heatmap, history bar |
| Popover | The panel that opens from the menu bar icon, holding the calendar, the habits, and Settings. | Window, menu, dropdown |
| Week start | The first day of the week, Sunday or Monday. It follows the Mac until the user overrides it in Settings. | First weekday |

## Tenets

- The prototype is the source of truth for behavior. When it and the PRD disagree, follow the prototype and bring the PRD in line (D-003).

## What the Agent Should Never Do

- Make the app send data anywhere but the user's own iCloud private database, or add a network entitlement, without a new decision (D-007, D-010).
