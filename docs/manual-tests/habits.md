# Manual Tests: Habits

**Why manual:** how the strip and rows look, VoiceOver's adjust gestures, a save failure (it needs a folder made read-only by hand), and many habits on a real screen are beyond what UI tests can see or set up.

## Habit rows look right in every appearance

**Setup:** a few habits, some done, some missed, one not due today.

1. Look at the popover in light mode, dark mode, and with Increase Contrast on.
2. Open the "1 not due today" row at the bottom of the list.

**Expect:** done squares and the filled done button are clearly green; missed squares soft red; not-scheduled squares faint grey; future days outlined; today's square ringed in the accent color; the habit not due today is hidden until the row opens, then has a dashed circle; the "not due today" row is readable but quieter than the rows. Nothing is hard to tell apart.

## Many habits scroll inside the popover

**Setup:** add habits until the list is taller than the screen (about 15 on a laptop).

1. Open the popover.

**Expect:** the calendar and the Habits header stay in place, the habit list scrolls, and the popover never runs off the bottom of the screen.

## VoiceOver adjusts the strip day by day

**Setup:** VoiceOver on (⌘F5), a habit with some missed days.

1. Move VoiceOver to a habit's strip. It reads "Push-ups, October 2026", then today's state.
2. Swipe up and down (or VO-↑/↓) to move between days.
3. Press VO-Space on a missed past day.

**Expect:** each day is read with its state ("October 28, missed"); VO-Space marks it done and VoiceOver reads "October 28, done".

## A failed save says so

**Setup:** HabitCal running with a habit. In Terminal: `chmod a-w ~/Library/Containers/com.muchfiner.HabitCal/Data/Library/Application\ Support/HabitCal` (use `.debug` for a development build).

1. Check off a habit.
2. Restore with `chmod u+w` on the same folder, then check off or undo another day.

**Expect:** after step 1, "Couldn't save — your last change may be lost" appears above the habits and the check-off stays on screen. After step 2 the message disappears.

## Copy and paste work in the habit form

**Setup:** a habit with a note.

1. Edit it, select the note, ⌘C; select the name, ⌘V; ⌘Z.

**Expect:** copy, paste, and undo all work in both fields.

## Streaks show at the right of each row

**Setup:** a habit with a current streak of 2, another of 3 or more, and one long streak (seed or check off by hand).

1. Open the popover; hover each number.

**Expect:** each row shows a fire with the current streak and a trophy with the best. At 3 or more the fire and its number turn orange and bold; below 3 they're grey. Tooltips read "Current streak" and "Best streak". Large numbers show in full (e.g. 1095), never abbreviated.
