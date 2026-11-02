# Retro: moments a prototype or spike should have been proposed

Task T-030, 2026-11-01. Sources:
- this project's only session log on this Mac (S-004, 2026-10-31 to 11-01; earlier sessions' logs aren't here);
- the git history from T-002 on;
- COMMON-FAILURE-MODES.md, especially FM-012;
- the review logs.

## 1. Decisions made on an untested platform or framework claim

| When | Claim acted on | How it turned out | Cost | Caught by |
| --- | --- | --- | --- | --- |
| T-002, D-005 (10-29) | `MenuBarExtra` "can't close itself or know when it opens" | False (T-029 spike) | T-017, T-027, FM-006 workarounds, several bug rounds | The customer, comparing with Apple's apps (FM-012) |
| T-032 (10-31) | `frame(minHeight:)` makes a screen at least that tall and taller when needed, inside the MenuBarExtra panel | False: the panel proposes its current height, and the delete confirmation was clipped | T-037, and a second rework in T-040 | The customer, on screen |
| T-005 icon (10-31) | `NSApp.applicationIconImage` returns the new app icon in a Debug, LSUIElement build | False: blank until macOS registers the icon | One round trip ("it looks blank") | The customer, on screen |
| T-034 (10-31) | Today's ring stays inside the strip's scroll view | False on the month's last day (the ring overflows right) | One bug report; T-018 had fixed only top and bottom | The customer, on screen |
| T-035 design (11-01) | "On the next main-actor turn" the panel is gone, so a dialog can follow | Not true (close is asynchronous) | None: caught before code | Design review, pass 1 |
| T-039 spike (11-01) | Xcode's command line can make a Developer ID profile | False ("No Accounts") | Customer time at developer.apple.com, plus one wrong-certificate round | The spike |
| T-039 slice 3 (11-01) | CKSyncEngine can be called from a `Task` started in its callback; its background scheduling works in the sandbox | Both false: a trap, and "BUG IN CLOUDKIT" | One crash and the 60 s fetch's importance | Running slice 3 for real |
| T-039 slice 1 (11-01) | `Date.ISO8601FormatStyle` writes milliseconds faithfully | False: it truncates | A reorder bug before it shipped | Unit test |

What went right, because of FM-012:
- The CloudKit spike (T-039) and the file-dialog spike (T-035) were proposed before design, and both changed the design. The spike showed the Developer ID profile path; the dialog spike showed the panel sits above dialogs.
- Every claim a spike didn't exercise was found later, by running the app or by review: engine callbacks, the date formatter, closing the panel.

## 2. Repeated complaints about one component

**The popover's sizing and layout** drew six reports in two days, each fixed locally:
- T-018: strips clipped at the bottom;
- T-024: column alignment;
- T-034: the ring clipped on the right;
- T-037: the delete confirmation clipped;
- T-040: Quit not at the bottom;
- the habit name truncated (11-01).

Every one is a SwiftUI layout behavior inside a fixed-width MenuBarExtra panel: what the panel proposes, what clips, what grows. None was checked on screen by the agent before the customer saw it. The customer's screen was the test.

**The habit row and strip** drew four rounds: strip clipping (T-018, T-034), the strip's design (T-041), and the name squeezed by the streaks (11-01). The row was laid out piece by piece, never as one thing with its longest name and its biggest numbers in mind.

## 3. Why they weren't caught

1. **Layout claims weren't treated as platform claims.** FM-012 and step 2 name OS behavior, library limits and performance. SwiftUI sizing inside the panel is just as much a platform behavior, but it was treated as code to write, not a question to check.
2. **"A mistake is visible on sight" assumed someone looks.** Trivial changes were committed without anyone seeing them, because the agent couldn't look and the customer said "test later". TESTING.md says "Check new screens by screenshot", but nothing in the process requires it, or says what to do when it can't be done.
3. **Spikes proved the API, not the event path.** The CloudKit spike proved a save and fetch, not engine callbacks over time, so the callback trap surfaced in slice 3.
4. **No trigger for a component's second complaint.** Each layout report became its own task, sized Trivial or Simple, with no step back to the component.

## 4. Proposed changes

Each one names the file it changes. Each would be logged in customizations.md.

1. **development.md, step 2, "Build one when":** add "a layout depends on how the container sizes its content (a popover or panel's proposed size, clipping, a scroll view's bounds)". Add to "Consider one when": "the customer has reported a problem with the same component twice in a phase. Then prototype or spike the component as a whole, at its extremes (longest name, largest numbers, most rows, shortest list), rather than fixing the second report alone."
2. **development.md, Trivial criteria 3:** "A mistake is visible on sight" becomes "A mistake is visible on sight, **and someone will look before it closes**". Add: for a UI change, the agent attaches a screenshot (TESTING.md's `XCTAttachment` route) or records "not seen on screen" in the commit and in TASKS.md, as this session did by hand.
3. **st-design §2, "audit":** a new line: "List the platform behaviors the design relies on, including layout and sizing in the app's container. Each one is spiked, cited, or tested; a spike exercises the same call path the design uses, such as events and callbacks over time, not only the API's availability."
4. **st-spec, Step 2, "watch for":** a third item: "**The same component again.** If this task is the second change in a phase to one component for a visual or layout problem, say so and recommend a prototype of the whole component at its extremes before writing rules for one symptom."
5. **COMMON-FAILURE-MODES.md:** a new FM-013, "SwiftUI sizing assumed inside the MenuBarExtra panel". Its examples are T-018, T-032/T-037, T-034, T-040 and the habit name. Its detection: any `frame(min…)`, `fixedSize`, `ScrollView` height, or overlay that draws past its bounds in a panel screen. Its recommendation: check at the extremes by screenshot.

Expected effect: four of the eight claims above, and three of the six layout reports, would have been caught by a check before the customer saw them.
