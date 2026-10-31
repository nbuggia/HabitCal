# Common Failure Modes

This knowledge base records recurring design-review failures. Every accepted
review finding is audited against this file before another review iteration.

The entries below are traps this stack is known for. None has been seen in this project yet.

## FM-001: Menu bar date goes stale after sleep or midnight

Symptoms:

- The icon shows yesterday's date after the Mac wakes, or after midnight passes while it sleeps.

Detection:

- Look for a date refresh driven only by a timer, or only by `NSCalendarDayChanged`.

Recommendation:

- Refresh on `NSCalendarDayChanged`, `NSWorkspace.didWakeNotification`, `NSSystemClockDidChange`, and `NSSystemTimeZoneDidChange`, plus a once-a-minute fallback check. Verify with the day-rollover manual test.

Examples:

- 

Frequency:

- High

Last Seen:

- 

## FM-002: Off-by-one days from storing instants instead of calendar days

Symptoms:

- Check-offs land on the wrong day after a time zone change or near a DST change. Streaks break for no reason.

Detection:

- Look for a `Date` in the model or the saved file standing for a calendar day, or for `addingTimeInterval(86400)`.

Recommendation:

- Use `Day` (year, month, day) for every calendar day. Convert from `Date` once, at the app's edge.

Examples:

- 

Frequency:

- High

Last Seen:

- 

## FM-003: Saving destroys data it couldn't read

Symptoms:

- After a failed decode (corrupt file, or one written by a newer version), the app starts empty and the next save replaces the user's history.

Detection:

- Look for a load path that falls back to an empty store on a decode error, and any save that isn't atomic.

Recommendation:

- An unreadable or newer-format file puts the store in a read-only state, and nothing is written (D-004). Write with an atomic replace.

Examples:

- 

Frequency:

- Medium

Last Seen:

- 

## FM-004: UI state changed off the main actor

Symptoms:

- Swift 6 concurrency errors, or crashes and missed updates from notification callbacks.

Detection:

- Look for notification observers, timers, or `Task`s that touch `AppModel` without `@MainActor`.

Recommendation:

- Keep `AppModel` `@MainActor`. Register observers on the main queue, or hop with `MainActor.assumeIsolated` / `Task { @MainActor in }`.

Examples:

- 

Frequency:

- Medium

Last Seen:

- 

## FM-005: Ignoring a change to the Mac's settings

Symptoms:

- After the user changes First day of week or the region, the calendar keeps the old week start until relaunch.

Detection:

- Look for `Calendar.current` stored in a property, and for a missing `NSLocale.currentLocaleDidChangeNotification` observer.

Recommendation:

- Use `Calendar.autoupdatingCurrent`, and redraw on locale changes.

Examples:

- 

Frequency:

- Medium

Last Seen:

- 

## FM-006: Popover focus and dismissal in a Dock-less app

Symptoms:

- The popover doesn't take keyboard focus (Tab, Esc, and typing in the form don't work), or it doesn't close on an outside click.

Detection:

- Check that `NSApp.activate()` runs before `popover.show`, that `popover.behavior = .transient`, and that a UI test types into the form.

Recommendation:

- Activate the app when showing the popover, use the `.transient` behavior, and test keyboard entry in a UI test.
- Route Esc through `cancelOperation` on the hosting controller, and make the hosting view first responder after each open and screen change.

Examples:

- T-002 design review: `.onKeyPress(.escape)` would have missed Esc in Settings with nothing focused, and NSPopover would have closed itself. Caught in review; `testEscapeLeavesSettingsThenClosesPopover` holds it.

Frequency:

- Medium

Last Seen:

- 

## FM-007: Tests that depend on the real date or real data

Symptoms:

- Tests pass or fail depending on the day they run, or a UI test run changes the developer's own habits.

Detection:

- Look for `Date()` in tests or the code under test, and for a UI test that launches without the fixed-date and temporary-data launch arguments.

Recommendation:

- Inject `Clock`, and give UI tests a fixed "today" and a temporary data directory.

Examples:

- 

Frequency:

- High

Last Seen:

- 

## FM-008: UI tests can't reach the status item

Symptoms:

- UI tests can't find or click the menu bar icon, so popover journeys go untested.

Detection:

- A spike UI test that clicks `app.statusItems.firstMatch` and finds the popover.

Recommendation:

- Prove it in T-002's first slice. If it's unreliable, add a test-only launch argument that opens the popover at launch, and keep clicking the icon as a manual check.

Examples:

- Not seen: on 2026-10-29 (Xcode 27.1, macOS 27), `app.statusItems["HabitCalStatusItem"].click()` works reliably.

Frequency:

- Medium

Last Seen:

- 

## FM-009: Login item registered from a translocated or Downloads copy

Symptoms:

- Launch at login silently stops working after the user moves the app to /Applications.

Detection:

- Look for `SMAppService.mainApp.register()` without a check of `Bundle.main.bundleURL`.

Recommendation:

- Register only when running from /Applications (T-002 E.9).

Examples:

- 

Frequency:

- Medium

Last Seen:

- 

## FM-010: A clamped or programmatic value doesn't reach a SwiftUI text field

Symptoms:

- A field shows more than its limit, or the text the user typed, while the model holds something else; Save then drops part of it.

Detection:

- A `TextField` bound through a custom `Binding` whose setter changes the value; a UI test that types past the limit and reads the field back.

Recommendation:

- Give the field its own `@State` text and enforce the limit in `.onChange`, then copy into the model.

Examples:

- T-003: the name field kept 45 characters while the draft held 40. `testNameStopsAtFortyCharacters` caught it; fixed in 6dd42c5.

Frequency:

- Medium

Last Seen:

- 2026-10-29

## FM-011: An SVG with gradients in the asset catalog stalls the UI

Symptoms:

- The popover never opens (UI tests time out on "popover didn't open") once a view showing the image is on screen; no crash and no log.

Detection:

- An `.svg` with `<linearGradient>` or `<radialGradient>` in `Assets.xcassets`. Swap the `Image` for a system image; if the problem goes away, it's this.

Recommendation:

- Keep the SVG as the source in `docs/artwork/` and ship a PDF made from it (`docs/artwork/make-flame-pdf.swift` shows how). Flat single-color SVGs (the Phosphor icons) are fine.

Examples:

- T-008: the streak flame as an SVG with three gradients stalled the popover whenever habits were listed; the PDF works.

Frequency:

- Low

Last Seen:

- 2026-10-30

## FM-012: Rejecting a native platform option on a claim nobody tested

Symptoms:

- The customer keeps reporting things that "don't feel like a Mac app" in one component (a gap, an arrow, the wrong material, the wrong highlight), and each fix is a workaround on top of the component rather than a change to it.
- A decision's Rejected line dismisses the platform's own component with a claim about what it "can't do", and no spike, test, or documentation link backs the claim.

Detection:

- In a design or decision, find every rejected alternative that is a native framework component (SwiftUI, AppKit, the OS). For each, ask: was the reason for rejecting it run on this OS, or only believed? If only believed, and the component is something users see every time they use the app, it needs a spike before the decision is Active.
- An HTML prototype that settled how a screen looks does not settle the native container it sits in (popover, panel, window, menu): the container's look and behavior come from the platform, not from the prototype.

Recommendation:

- Spike the rejected native option before choosing the custom one, at the moment of the decision (step 2 of development.md: "a technical assumption needs proof before design, such as an OS behavior"). The spike asks the exact questions the rejection rests on, runs on the customer's Mac, and logs what happened.
- For the most visible surface of the product (for a menu bar app: what opens from the icon), compare it side by side with the platform's own apps before building on it.

Examples:

- T-002 / D-005 (2026-10-29): `MenuBarExtra` was rejected for "no supported way to close itself or to know when it opens" without a spike, and an `NSPopover` was built instead. The T-001 prototype was HTML, so it couldn't show the popover's arrow, gap, or glass. It cost T-017 (the gap), T-027 (a hand-made icon highlight), the FM-006 workarounds (a hosting controller for Esc, refocus hooks, a reopen guard), and several rounds of the customer's bug reports, until the customer compared it with Apple's Now Playing on 2026-10-30. A 30-minute spike (T-029) then showed `MenuBarExtra` could do everything D-005 needed, and D-009 replaced it.

Frequency:

- Medium

Last Seen:

- 2026-10-30
