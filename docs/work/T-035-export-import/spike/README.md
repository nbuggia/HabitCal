# Spike: does a file dialog from HabitCal come to the front?

## Question

T-035's dialogs (E.8) come from a sandboxed app with no Dock icon (LSUIElement) whose panel is a MenuBarExtra (D-009). On the customer's Mac (macOS 27):

1. After `NSApp.activate()`, does an `NSSavePanel` run with `runModal()` show in front of other apps' windows?
2. Does it need anything beyond the user-selected read-write entitlement?

Build: `./build.sh <dir>`, then run `<dir>/DialogSpike.app/Contents/MacOS/DialogSpike` and, while its panel is up, `<dir>/check` to list on-screen windows front to back. The spike opens the panel a second after launch and aborts it three seconds later, so nobody has to click.

## Answer

**Yes** (2026-11-01). With the panel open, `check` listed:
- DialogSpike's save panel (370×204) at **layer 8**, the modal-panel level, in front of every app window (layer 0: Safari, Claude, and others);
- HabitCal's own MenuBarExtra panel (232×380, open on the customer's screen at the time) at **layer 101**, above it.

What follows for T-035:
- The dialogs come to the front with `NSApp.activate()` and the modal-panel level.
- HabitCal's panel sits above modal panels, so it **must close before a dialog opens**, or it would cover the dialog. The design closes it first (with `cancelOperation`, T-029) instead of finding out whether it closes on its own.
- The user-selected read-write entitlement is enough to show the panel; ad-hoc signing with the sandbox worked.

Not proven: clicking Save and writing the file, since nobody clicked. That's a manual check in T-035's first slice.
