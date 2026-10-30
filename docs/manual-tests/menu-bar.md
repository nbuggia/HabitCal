# Manual Tests: Menu Bar

**Why manual:** these depend on how macOS draws the menu bar, and on real time and system events (midnight, sleep, clock and time zone changes) that a UI test can't produce.

## The icon is legible at actual size in every menu bar appearance

**Setup:** HabitCal running.

1. Look at the icon in a light menu bar, then a dark one (System Settings › Appearance).
2. Choose a colorful wallpaper so the menu bar is tinted.
3. Turn on System Settings › Accessibility › Display › Increase Contrast.

**Expect:** a rounded calendar page with the month in capitals (OCT) cut out of a solid top bar and today's day below. It's crisp and readable each time, the same color as the other menu bar icons, with no box or halo around it. Clicking it shows the normal highlight behind the whole icon, letters included.

## The icon shows the new date after midnight

**Setup:** HabitCal running, the Mac awake, a few minutes before midnight.

1. Wait until midnight passes.

**Expect:** within a minute, the icon shows the new day (and the new month on the 1st), without relaunching.

## The icon shows the new date after sleeping through midnight

**Setup:** HabitCal running in the evening.

1. Put the Mac to sleep before midnight, and wake it the next morning.

**Expect:** within a minute of waking, the icon shows today's date.

## The icon follows a clock or time zone change

**Setup:** HabitCal running.

1. In System Settings › General › Date & Time, turn off "Set time and date automatically" and set the date to tomorrow. Then turn it back on.
2. Change the time zone to one where it's already tomorrow (e.g. from New York to Tokyo in the evening), then change it back.

**Expect:** after each change, the icon shows the matching date within a minute.

## Today's circle moves at midnight while the popover is open

**Setup:** HabitCal running, the popover open, a minute before midnight.

1. Leave it open across midnight.

**Expect:** within a minute, the filled circle moves to the new day and the popover stays open. The displayed month doesn't change, even on the 1st.

## The calendar follows the Mac's first day of the week

**Setup:** HabitCal running, no week-start override in Settings.

1. In System Settings › General › Language & Region, set First day of week to Monday.
2. Open the popover.
3. Set it back to Sunday, and open the popover again.

**Expect:** the calendar's columns start on Monday, then on Sunday, without relaunching.
