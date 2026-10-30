---
name: Menu bar date and month calendar
task: T-002
status: Approved
last updated: 2026-10-29
---

# Spec: Menu Bar Date and Month Calendar

## 1. Summary

HabitCal's menu bar icon, the popover it opens, the popover's month calendar, and Settings. The icon is a tear-off calendar page that always shows today's month and day. One click opens a month calendar you can page through, with Settings one click away. This is the shell the habits (T-003) and streaks (T-004) live in, and it's useful alone: today's date at a glance and any month in a click.

## 2. Users

- **For:** a Mac user who glances up to check the date, or wants to look up a date or day of the week in this or another month.
- **Core value:** the icon shows today's date correctly at all times, with no click, and any month is one click per month away.
- **Not for:** anyone who wants calendar events, meetings, or time zones. Itsycal and Calendr already do that well.

## 3. Not Doing

- Calendar events from Apple Calendar, Google, or iCloud. They would add permission prompts and pull the app toward being a meeting tool (PRD Not Doing).
- Showing a progress indicator in the icon. A ring and a top/bottom line were tried in the prototype and removed to keep the icon calm.
- Showing completion marks on the calendar grid. The per-habit strips (T-003) carry the history, and the prototype's grid shows dates only.
- Clicking a day in the grid does nothing. The prototype gives days no action, and the strips handle editing past days.
- A Dock icon or app window. HabitCal is a menu bar app (PRD Constraints).

## 4. Current Behavior

New feature; nothing exists today.

## 5. UI

From the T-001 prototype, which is the source of truth for anything visual.

- **Menu bar icon:** a rounded-rectangle calendar page about the height of the menu bar's other icons. The top is a solid header bar with the month's three-letter abbreviation in capitals ("OCT") cut out of it, so the menu bar shows through the letters. Today's day number sits below it, bold. All four corners are rounded. It is drawn in a single color that matches the other menu bar icons in light and dark menu bars.
- **Popover:** opens beneath the icon, about 330 pt wide, and shows one screen at a time: the habit list (calendar on top, habits below) or Settings.
- **Calendar header:** "October 2026" on the left. On the right are three buttons: Previous month (‹), Today (a calendar-with-dot icon), and Next month (›).
- **Calendar grid:** a row of weekday initials (S M T W T F S, in week-start order), then six weeks of days, always 42 cells. Days from the neighboring months show in a faint color. Today's number sits in a filled accent-colored circle.
- **Footer** (below the habits): "+ Add habit" (T-003) on the left, a gear button on the right that opens Settings.
- **Settings screen:** a header with "‹ Back" and the title "Settings". Below it:
  1. An About line: **HabitCal 1.0** (the app's version), with www.muchfiner.com as a link below it.
  2. A "General" group with two rows:
     - **Launch at login**, a switch, captioned "Start HabitCal when you log in to this Mac".
     - **Week starts on**, a Sunday / Monday segmented control. Its caption reads "From your Mac's settings" while it follows the Mac. While overridden, it reads "Your Mac uses ‹day› · Use Mac setting", where "Use Mac setting" is a link.
  3. At the bottom, "Quit HabitCal" with a power icon and the shortcut ⌘Q.
- **Icons:** Phosphor, regular weight.

## 6. Use Cases

| Use case | Journey | How to verify |
| --- | --- | --- |
| UC-1 Check today's date | Glance at the menu bar; the icon shows today's month and day. | UI test of the icon's date; manual test across midnight and sleep |
| UC-2 Look up another month | Click the icon, page forward or back with ‹ ›, and return with Today. | UI test |
| UC-3 Set the week start | Open Settings and pick Monday; the calendar reorders. Later choose "Use Mac setting". | UI test, plus a manual test that changes the Mac's setting |
| UC-4 Launch at login | Toggle it in Settings; HabitCal starts, or doesn't, at the next login. | Manual test |
| UC-5 Quit | Open Settings and click Quit, or press ⌘Q while the popover is open. | UI test |

## 7. Behavior

### New

**Menu bar icon**

B.1 WHILE HabitCal is running THE SYSTEM SHALL show the icon in the menu bar with today's month abbreviation and day number, in the Mac's local time.

B.2 WHEN the local date changes THE SYSTEM SHALL update the icon within one minute, without a relaunch. This covers midnight, waking from sleep, a time zone change, and a manual clock change.
Why: the date is the app's first job (PRD Done Means), and the Mac sleeping through midnight is the common way menu bar clocks go stale.

B.3 THE SYSTEM SHALL NOT show a Dock icon or appear in the app switcher.

**Popover**

B.4 WHEN the user clicks the icon THE SYSTEM SHALL open the popover showing the habit list screen and the current month.
Why: every open starts from today, so the popover never opens on a stale month or a half-finished screen.

B.5 WHEN the popover is open and the user clicks the icon again or clicks anywhere outside the popover THE SYSTEM SHALL close it. Esc is checked in order: it closes an open right-click menu (T-003 B.17); otherwise it returns from the habit form or Settings to the list; otherwise it closes the popover.

**Month calendar**

B.6 THE SYSTEM SHALL show the displayed month as six weeks of seven days starting on the week-start day (B.12), with the neighboring months' days shown faint.

B.7 THE SYSTEM SHALL mark today with the filled accent circle whenever today is visible in the grid, including as a faint neighboring-month day.

B.8 WHEN the user clicks Previous month or Next month THE SYSTEM SHALL show the month before or after, across year boundaries, with the header updated to match ("December 2026" → "January 2027").

B.9 WHEN the user clicks Today THE SYSTEM SHALL show the current month.

B.10 THE SYSTEM SHALL allow paging to any month, past or future, with no limit.

**Settings**

B.11 WHEN the user clicks the gear THE SYSTEM SHALL replace the habit list with Settings. WHEN they click Back THE SYSTEM SHALL return to the habit list, showing the same month as before. Settings changes apply immediately; there is no Save.

B.12 Week start. While the user hasn't chosen one, THE SYSTEM SHALL use the first day of the week from the Mac's settings (System Settings › General › Language & Region › First day of week), and keep following it if that setting changes, while HabitCal is running or between launches. If the Mac's first day is anything other than Monday, THE SYSTEM SHALL use Sunday. "The day the Mac uses" in B.13 and B.14 means the day after this mapping.
Why: the settings offer only Sunday and Monday, and this is the prototype's mapping.

B.13 WHEN the user picks the day in Week starts on that the Mac doesn't use THE SYSTEM SHALL override the Mac's setting with it. WHEN they pick the day the Mac already uses while there is no override THE SYSTEM SHALL keep following the Mac. WHEN they pick a day while an override is on THE SYSTEM SHALL keep an override set to that day, even if it matches the Mac; only "Use Mac setting" removes it.
Why: picking what the Mac already says isn't an override, so a later change to the Mac's setting still takes effect. Once the user has overridden, their explicit picks stick. Both follow the prototype.

B.14 WHILE an override is on THE SYSTEM SHALL show "Your Mac uses ‹Weekday›" and a "Use Mac setting" link. WHEN the user clicks the link THE SYSTEM SHALL remove the override and follow the Mac again.

B.15 THE SYSTEM SHALL apply the week start to the calendar grid's columns and to the order of the habit form's day buttons (T-003), immediately, and remember the override across relaunches.

B.16 WHEN the user turns on Launch at login THE SYSTEM SHALL register HabitCal to start when the user logs in, and unregister it WHEN they turn it off. The switch SHALL show whether HabitCal is actually registered, read each time Settings opens.

B.17 On the first launch from the Applications folder THE SYSTEM SHALL turn Launch at login on, unless the user has already turned it off.
Why: the prototype ships it on, and a menu bar date that disappears after a restart fails the app's first job. Waiting for /Applications avoids registering a copy running from Downloads (E.9).

B.18 WHEN the user clicks www.muchfiner.com THE SYSTEM SHALL open https://www.muchfiner.com in the default browser and close the popover.

B.19 WHEN the user clicks Quit HabitCal, or presses ⌘Q while the popover is open, THE SYSTEM SHALL quit. A menu bar app has no Dock icon, so Settings is the only way to quit.

## 8. Limits

- Calendar grid: always 6 rows × 7 columns, so the popover doesn't change height from month to month.
- Icon date staleness: at most 1 minute after the local date changes (B.2).
- Supported week starts: Sunday and Monday only.

## 9. Edge Cases and Errors

E.1 WHEN the date changes while the popover is open THE SYSTEM SHALL move today's circle to the new day without closing the popover or changing the displayed month.

E.2 WHEN a second copy of HabitCal is launched while one is running THE SYSTEM SHALL keep a single menu bar icon. The new copy exits.

E.3 WHEN macOS needs the user's approval before HabitCal can launch at login THE SYSTEM SHALL show the switch as off. Its caption then reads "Needs approval in System Settings › General › Login Items", and clicking the caption opens that pane.

E.4 WHEN registering or unregistering for launch at login fails THE SYSTEM SHALL return the switch to the actual state and leave the rest of Settings working.

E.5 WHEN the user removes HabitCal from Login Items in System Settings THE SYSTEM SHALL show Launch at login as off the next time Settings opens. Opening Settings never turns it back on.

E.6 Keyboard and VoiceOver: every control in the popover SHALL be reachable with Tab and have a spoken label: "Previous month", "Today", "Next month", "Settings", "Back", "Launch at login", "Week starts on", "muchfiner.com", "Use Mac setting", "Open Login Items settings" (E.3's caption), and "Quit HabitCal". VoiceOver SHALL read each grid day as its full date ("Thursday, October 29, 2026"), with ", today" for today.

E.7 THE SYSTEM SHALL draw the icon and popover correctly in light mode, dark mode, and with Increase Contrast on, and the icon SHALL stay legible on a tinted or wallpaper-colored menu bar.

E.8 WHEN the menu bar is crowded and macOS hides the icon THE SYSTEM SHALL do nothing special. This is accepted: menu bar apps can't control it.

E.9 WHEN HabitCal runs from anywhere but /Applications, for example straight from Downloads, THE SYSTEM SHALL NOT register for launch at login. B.17 applies on the first launch from /Applications.
Why: a GitHub download's first launch often runs from Downloads or a temporary path macOS creates, and a login item pointing there breaks once the app is moved.

E.10 WHILE HabitCal runs from anywhere but /Applications THE SYSTEM SHALL show the Launch at login switch as off and disabled, with the caption "Move HabitCal to Applications to launch at login".
Why: E.9 forbids registering from there, so a switch the user could turn on would be lying. Added during T-002's design.

## 10. Contracts

- ⌘Q quits HabitCal while the popover is open.
- The About link opens https://www.muchfiner.com.

## 11. Success Criteria

- The icon never shows yesterday's date after a sleep through midnight (PRD Done Means).
- Any month is one click per month away, and one click returns to today (PRD Done Means).

## 12. Deferred

- Keyboard shortcuts to page months (← / →) and jump to today — nice to have, not in the prototype.
- A global hotkey to open the popover — not in the prototype.
- Localizing the app beyond English — v1 ships in English.
- Week numbers in the grid — not in the prototype.

## 13. Assumptions

- The app's interface, including month and weekday names, is in English for v1, whatever the Mac's language.
- The version on the About line is the app's real version, shown as major.minor ("1.0"), not a hard-coded string.
- "Within one minute" (B.2) is precise enough. The icon has no time on it, so a second-level rollover adds nothing.

## Review Findings

One st-crit pass covered T-002, T-003, and T-004 together. Verdict: CONCERNS, no blockers.

| # | Severity | Finding | Decision | Source |
| --- | --- | --- | --- | --- |
| 1 | MAJOR | Nothing promised that data survives an app update | ACCEPT: T-003 B.18, and a versioned saved-data contract (T-003 §10) | Pass 1 |
| 2 | MAJOR | Launch at login on first launch registers a copy running from Downloads | ACCEPT: B.17 waits for /Applications; added E.9 | Pass 1 |
| 3 | MINOR | Esc rules contradicted each other across specs | ACCEPT: B.5 gives the order Esc is checked in | Pass 1 |
| 4 | MINOR | A done-button click just after midnight, and time zone changes, were undefined | ACCEPT: T-003 B.4, B.19, and E.3 | Pass 1 |
| 5 | MINOR | Week-start mapping and override rules differed from the prototype | ACCEPT: B.12 and B.13 now follow the prototype | Pass 1 |
| 6 | MINOR | Adding a habit while the data is unreadable would overwrite it | ACCEPT: T-003 E.5 disables Add and saving | Pass 1 |
| 7 | MINOR | One Tab stop per strip square; some spoken labels missing | ACCEPT: T-003 E.8 and E.6 | Pass 1 |
| 8 | MINOR | Done-button tooltips from the prototype were missing | ACCEPT: T-003 §5 | Pass 1 |
