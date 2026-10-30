# Decisions

<!--
Newest entry first. Entries are never edited or deleted; when a decision
changes, add a new entry and set the old one's Status to "Superseded by D-NNN".

## D-NNN · Short title · YYYY-MM-DD
Status: Active
Context: What prompted the decision.
Decision: What was chosen.
Why: The reasoning.
Rejected: Alternatives considered and why not. (optional)
Affects: Task IDs and files this touches. (optional)
-->

## D-004 · Habit data stays on the Mac, versioned and never overwritten when unreadable · 2026-10-29
Status: Active
Context: The T-003 spec defines how habits are saved. Its review found that the next HabitCal release is the first reader of v1's data.
Decision: Habit data is saved only on the Mac, and HabitCal makes no network requests. The saved data carries a format version. Every newer HabitCal reads every earlier format. Data HabitCal can't read, including a newer format, is never overwritten.
Why: Streak history is the product's value, and losing it on an update or a downgrade is the worst failure. Local-only, with no account, is a differentiator (PRD Appendix).
Rejected: An unversioned format, fixed up later. Builds already shipped would have written it to disk, so a later fix can't reach them.
Affects: T-003, T-004

## D-003 · The prototype wins over the PRD: no day marks on the grid, notes allowed · 2026-10-29
Status: Active
Context: While specifying v1, the T-001 prototype and PRD.md disagreed. The PRD promised all/part/none marks on each calendar day and excluded habit notes; the prototype has neither marks nor that exclusion.
Decision: The prototype is the source of truth for v1's behavior. The calendar grid shows dates only, and each habit's month strip carries the history. Habits have an optional note. The objective was reworded to match.
Why: The customer chose the prototype's design deliberately while iterating on it. Day marks would duplicate the strips in a 330 pt popover.
Rejected: Completion marks on each grid day. The strips already show the same history, per habit.
Affects: PRD.md, T-002, T-003

## D-002 · Product name: HabitCal · 2026-10-29
Status: Active
Context: CalAccrue (D-001) needed its "small habits accrue" story explained before it clicked, and was easy to misspell.
Decision: Name the app HabitCal, with a capital C.
Why: It names both jobs, habits and the calendar, at a glance, and matches what people search for. Distribution is GitHub, not the App Store, so a crowded field of similar store names matters less. A quick web search on 2026-10-29 found no App Store app named HabitCal.
Rejected: CalAccrue. More distinctive, but it reads slower. Known overlap with HabitCal: Everyday Systems runs a free web habit tracker by that name (habitcal.everydaysystems.com). Accepted, since it's a small web tool, not a Mac app.
Affects: PRD.md, T-001

## D-001 · Product name: CalAccrue · 2026-10-29
Status: Superseded by D-002
Context: The working name "tcal" read as an abbreviation and said nothing about habits.
Decision: Name the app CalAccrue, with a capital A, a blend of "calendar" and "accrue": small daily habits add up to something big.
Why: It names both jobs, the calendar and the build-up of habits. Spelling "accrue" correctly behind the capital A makes it read instantly. No App Store app (US, Mac or iPhone/iPad) used the name on 2026-10-29.
Rejected: Daymark, Dayleaf, Diem, Cadence, Cairn, Calacrue, Calcrue, Daycrue. They were good options, but none named both jobs as directly. "Accrue" alone is taken by several finance apps.
Affects: PRD.md, T-001
