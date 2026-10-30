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

## Clicking outside closes the popover

**Setup:** the popover open.

1. Click the desktop, another app's window, or another menu bar item.

**Expect:** the popover closes. Opening it again shows the current month.

## HabitCal has no Dock icon or app-switcher entry

**Setup:** HabitCal running.

1. Look at the Dock, and press ⌘Tab.

**Expect:** no HabitCal icon in either.

## Launch at login turns on once, on the first launch from Applications

**Setup:** a build of HabitCal copied to /Applications that has never run there. Log out and in afterward.

1. Open it from /Applications, then open Settings.
2. Log out and back in.

**Expect:** Launch at login is on, and HabitCal is in the menu bar after logging in. (Repeat on T-005's signed build; ad hoc signing can behave differently.)

## Turning Launch at login off sticks

**Setup:** HabitCal in /Applications, Launch at login on.

1. Turn the switch off, quit, reopen HabitCal, and open Settings.
2. Log out and back in.

**Expect:** the switch is still off, and HabitCal doesn't start at login.

## Launch at login follows System Settings

**Setup:** HabitCal in /Applications, Launch at login on.

1. In System Settings › General › Login Items, turn HabitCal off.
2. Open HabitCal's Settings.

**Expect:** the switch shows off, with the caption "Needs approval in System Settings › General › Login Items". Clicking the caption opens that pane. Opening Settings never turns it back on.

## A copy outside Applications never launches at login

**Setup:** a fresh copy of HabitCal in Downloads.

1. Open it from Downloads, then open Settings.

**Expect:** the switch is off and disabled, captioned "Move HabitCal to Applications to launch at login", and System Settings › Login Items doesn't list HabitCal.

## A second copy exits

**Setup:** HabitCal running.

1. Open a second copy (the same build, or one from another folder).

**Expect:** still exactly one HabitCal icon in the menu bar.

## The website link opens the browser

**Setup:** HabitCal running.

1. Open Settings and click www.muchfiner.com.

**Expect:** https://www.muchfiner.com opens in the default browser, and the popover closes.

## Keyboard and VoiceOver reach every control

**Setup:** System Settings › Keyboard › Keyboard navigation on; VoiceOver on (⌘F5).

1. Open the popover and press Tab repeatedly, on the list and in Settings.
2. Move VoiceOver over the icon, the calendar days, and each control.

**Expect:** Tab reaches every button, the switch, the Sunday/Monday control, and the link. VoiceOver reads the icon as "HabitCal, Thursday, October 29", each day as its full date ("…, today" on today), and each control by name.
