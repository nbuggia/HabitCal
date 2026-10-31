# Product: HabitCal

## Outcome

HabitCal is a free macOS menu bar app for people building daily habits. The menu bar always shows today's date; one click opens a month calendar you can page through, with your habits right under it: check off today's from the popover, and see at a glance, in each habit's strip for the month on show, which days you kept up. Each habit has its own schedule (push-ups every day, a run on Fridays and Sundays), and its streak counts only the days it was due, so a day off never breaks it. It matters because today this takes two apps — a menu bar calendar and a habit tracker — and the good habit trackers are paid, capped, or want an account. HabitCal does both jobs in one glance, privately, for free. See the Appendix.

## Done Means

- The menu bar shows today's date at all times and rolls over at midnight without a relaunch, including after the Mac wakes from sleep.
- One click opens the current month; any other month is one click per month away, and one click returns to today.
- A new habit with a schedule (every day, or chosen weekdays) can be added in under 30 seconds.
- Checking off today's habit is one click from the popover; its streak updates immediately and survives quitting and relaunching.
- Each habit shows a strip for the month on show in the calendar, marking each day as done, missed, or not scheduled.
- Each habit shows its current streak and its best streak, and a day the habit wasn't scheduled never breaks a streak.
- A missed check-off can be fixed by marking a past day done.
- The app works fully offline, needs no account, and sends no data anywhere.

## Not Doing

- **Calendar events.** No Apple Calendar, Google, or iCloud events. Itsycal and Calendr do that well and for free; it would add permission prompts and pull HabitCal toward a meeting tool.
- **Sync, accounts, or iPhone/iPad apps.** v1 is one Mac with local data. Sync is the main source of complexity and cost in competing apps.
- **Counted or timed goals** ("50 push-ups", "30 minutes"). A habit is done or not done for the day. Revisit after v1 (see BACKLOG.md).
- **Reminders and notifications.** HabitCal is glanceable, not a nag. Revisit after v1.
- **Payments, ads, habit limits, or social features.** The app is free with no ceiling — the category's upsells and social feeds are what users complain about.

## Constraints

- macOS only, as a menu bar app with no Dock icon.
- Free to users, forever.
- Native: Swift and SwiftUI, no third-party dependencies, macOS 15 (Sequoia) or later.
- Distributed as a signed, notarized download from GitHub; the Mac App Store can come later.

## Feature: Menu Bar Date

**For:** anyone who glances up to check the date.
**Why it matters:** it's the first job of the app and the reason it stays in the menu bar; it must be right every time, without a click.

## Feature: Month Calendar

**For:** someone looking up a date, or a day of the week, in this or another month.
**Why it matters:** a month grid in one click replaces opening Calendar.app — and it's the canvas the habit history is drawn on.

### Not Doing
- Checking off future days. A selected future day shows its habits, read-only (T-022).

### Flows
- Spans Habits: selecting a day shows that day's habits and whether each was done; on a past day you can fix them there, without hunting for its square in the strip (T-022). Today keeps a light marker so it's always easy to find.

## Feature: Habits

**For:** someone building a few recurring habits — some daily, some on specific weekdays.
**Why it matters:** checking off a habit has to be quicker than skipping it, or the tracking stops.

The list shows the habits due today; the others fold into a quiet "N not due today" row that opens to show them, so today's list stays short (T-012).

### Not Doing
- Habit categories or journaling — keep the list short and flat. An optional note per habit ("3 sets of 20") is fine (D-003).
- Hiding not-due habits with no way back — they couldn't be edited that day (T-012).
- Remembering whether the "N not due today" row is open (T-012).

## Feature: Streaks

**For:** the same person, wanting to see momentum and not break the chain.
**Why it matters:** the streak is the motivation; it must be fair — a run that's due only on Fridays and Sundays keeps its streak through the week in between.

## Feature: Leaderboard

**For:** someone with several habits who wants to see which ones they actually keep up.
**Why it matters:** ranking by the share of due days done, not a count, lets a habit due twice a week compete fairly with a daily one (T-016).

### Not Doing
- Ranking by current streak, or a this-week view with each day as a dot — the other two options in the T-015 prototype.
- Calendar weeks and months. The ranges are rolling windows ending today.

## Appendix: Competitive Analysis

Researched 2026-10-29. Prices and features change; re-check before relying on a specific claim.

### Summary

The market splits cleanly in two, and nothing occupies the middle:

- **Menu bar calendars** (Itsycal, Calendr, Menu Bar Calendar, Dato) answer "what's the date?" in one click, are mostly free, and know nothing about habits.
- **Habit trackers** (Streaks, Habitify, Habits, Kinetik) handle schedules and streaks well, but live in a window, a widget, or a today-only menu bar list — none put habit history on a month calendar in the menu bar. The good ones are paid or freemium with subscriptions.

A Mac user who wants both runs two apps today. HabitCal's position: **one free, private menu bar icon that is both — the month calendar with each habit's month of history right under it.**

### Menu bar calendars

| App | Price | Strengths | Gaps vs. HabitCal |
| --- | --- | --- | --- |
| [Itsycal](https://alternativeto.net/software/itsycal) | Free, open source | The default recommendation. Tiny month grid, date in menu bar, Calendar events | No habits |
| [Calendr](https://github.com/pakerwreah/Calendr) | Free, open source (MIT), ~2.4k stars | Itsycal-style with more: events, reminders, multiple time zones, URL scheme to open a date | No habits; growing feature surface |
| [Menu Bar Calendar](https://mac.softpedia.com/get/System-Utilities/Menu-Bar-Calendar.shtml) (Sindre Sorhus) | Free | Pure month overview — the closest match to HabitCal's calendar job | No habits, deliberately minimal |
| [Dato](https://alternativeto.net/software/dato) | Paid, one-time | Highly customizable: events, world clocks, week numbers, notifications | Paid; no habits |
| [CalendarMenu 4](https://apps.apple.com/app/id510684580) | $3.99 | Upcoming appointments, birthdays, reminders | Paid; no habits |
| Day-O, Calendar 366, Dot Calendar, Superpowered, MeetingBar, [Daybar](https://alternativeto.net/software/daybar) | Free to paid | Event / meeting oriented; Daybar adds tasks and Pomodoro | Meeting tools, not habit tools |
| [MonthBar](https://alternativeto.net/software/monthbar/about) | Free | Month-progress pie in the menu bar; offline, no tracking | Shows progress only — no calendar grid, no habits |

### Habit trackers on the Mac

| App | Price | Mac form | Scheduling | Streaks | Gaps vs. HabitCal |
| --- | --- | --- | --- | --- | --- |
| [Streaks](https://streaksapp.com/) | $5.99 one-time | App window (Catalyst port of the iPhone app) | Specific weekdays, N days/week, N days/month, every other day | Off days don't break the chain; the category leader | Not a menu bar app; 24-habit limit; paid |
| [Habitify](https://feedback.habitify.me/changelog/habitify-for-macos-update-new-mini-app-and-more-updates) | Free plan; $39.99/yr or $89.99 lifetime | App + menu bar mini app (Aug 2025) showing today's list | Flexible | Yes | Account and sync; subscription upsell; menu bar shows today only, no month |
| [Habits](https://dgrcode.gumroad.com/l/habits/REDDIT) | $9.99+ | Menu bar | Unconfirmed | Unconfirmed | Paid; no calendar |
| [Kinetik](https://www.producthunt.com/products/kinetik-native-macos-habit-tracker) | Free, open source (SwiftUI) | Desktop widgets | Everyday / weekdays / weekends / custom | Yes, with a 3 AM rollover so late nights count for the previous day | Not in the menu bar; beta |
| [dAb Everyday](https://www.jkemppainen.com/?p=4447) | Free | App + desktop widgets mirroring a habit's month | — | Year-at-a-glance grid | One habit per widget; not a menu bar app |
| [Everyday](https://timingapp.com/blog/habit-tracker-apps-iphone-mac/) | 3 habits free; $2.50/mo | Apple devices | No flexible scheduling | Current and best streak, visual grid | Paywall at 3 habits; no weekday schedules |
| [TickTick](https://timingapp.com/blog/habit-tracker-apps-iphone-mac/) | Free; $35.99/yr | Full productivity suite | N times per week | Optional | Habits are secondary in a large app |
| HabitMinder, Strides, Awesome Habits | Freemium | iPhone + Mac | Varies | Varies | Heavier, goal/metric oriented, upsells |

Source for the habit-tracker roundup: [Timing — Best Habit Tracker Apps for iPhone and Mac](https://timingapp.com/blog/habit-tracker-apps-iphone-mac/).

### What we learn from them

**Table stakes** — users of this category expect these, so HabitCal must have them:

- Today's date in the menu bar, month grid one click away, quick jump back to today (Itsycal, Menu Bar Calendar).
- Per-habit schedules on specific weekdays, where an unscheduled day never breaks a streak (Streaks, Kinetik).
- A current streak per habit, and the best streak ever (Everyday).
- Check off today's habit without opening a window (Habitify mini app, Habits).
- Local, private data with no account (Kinetik, MonthBar) — a real differentiator against Habitify and Everyday.

**Where HabitCal can win:**

1. **The month calendar and the habit history in one place.** Nobody puts a month of habit history under a menu bar calendar. You see "what's the date" and "how am I doing this month" in one glance.
2. **Free with no ceiling.** Streaks is paid; Everyday caps free at 3 habits; Habitify upsells. HabitCal is free with no limits and no account.
3. **Small and calm.** Category reviews repeatedly fault busy interfaces, upsells, and social features (Habitify, TickTick, Fabulous). HabitCal does two jobs and stops.

**Ideas worth borrowing later** (not v1): a day-rollover hour for night owls (Kinetik's 3 AM), "N times per week" schedules (Streaks, TickTick), skip/excused days that don't break a streak (Way of Life, HabitMinder), counted goals (Strides).

**Traps to avoid:** habit limits and paywalls, accounts and sync in v1, social features, and a growing settings surface — Calendr shows how a menu bar calendar accumulates features.
