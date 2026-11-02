# Manual Tests: Habits

**Why manual:** how the strip and rows look, a save failure (it needs a folder made read-only by hand), and many habits on a real screen are beyond what UI tests can see or set up.

## Habit rows look right in every appearance

**Setup:** a few habits, some done, some missed, one not due today.

1. Look at the popover in light mode, dark mode, and with Increase Contrast on.
2. Select a day in the calendar the habit not due today is due on.

**Expect:** each strip shows only the habit's due days, 30 squares, oldest on the left; done squares and the filled done button are clearly green; missed squares soft red; squares before the habit was added faint grey; future days outlined; the newest square (the day shown) ringed in the accent color; clicking a square does nothing, and VoiceOver skips the strip; the habit not due today isn't listed until you select one of its days. Nothing is hard to tell apart.

## Many habits scroll inside the popover

**Setup:** add habits until the list is taller than the screen (about 15 on a laptop).

1. Open the popover.

**Expect:** the calendar and the bottom row stay in place, the habit list scrolls, and the popover never runs off the bottom of the screen.

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

## Buttons answer the pointer

**Setup:** a habit or two, light mode then dark mode.

1. Hover over, then press and hold, each kind of button: the calendar's arrows and Today; the bottom row's +, trophy, and Settings; a done button; a habit's name; Back; the form's Close, Add, day circles, and Delete habit; Quit; the leaderboard's tabs.
2. Make Add unavailable (an unreadable data file) and hover over it.
3. Hover a done button, press Esc, then reopen the popover.
4. Turn on Keyboard navigation (System Settings › Keyboard) and Tab through the list and the form.

**Expect:** a soft highlight on hover and a darker one while pressed, shaped to the button (round for the done button and day circles). Text doesn't shift. Button colors match the previous build (borderless icons and Back may have been tinted). Disabled buttons are dimmed but still legible, and don't highlight. After reopening, no button is left highlighted. With Keyboard navigation on, the focused button shows the highlight.

