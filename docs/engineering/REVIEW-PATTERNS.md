# Review Patterns

Use these prompts alongside `COMMON-FAILURE-MODES.md` during technical-design
review. They are checks, not implementation prescriptions.

## "Today" Review

- Name every place that reads the current date. Is each one the injected `Clock`, converted to a `Day` once?
- Which events change "today": midnight, wake, clock change, time zone change? Is each one observed, and is there a fallback timer?
- What does each screen show while the date changes under it?

## Platform Choice Review

- For each rejected alternative that is a native component (SwiftUI, AppKit, the OS): was the reason it was rejected run on this OS, or only believed? If only believed, ask for a spike before approving (FM-012).
- Does the most visible surface (what opens from the menu bar icon) look and behave like the platform's own apps? Has anyone compared them side by side?

## Menu Bar Popover Review

- Who opens and closes the popover, and what state is reset on each open?
- Does the popover get keyboard focus (Tab, Esc, typing) in a Dock-less app?
- How does a UI test reach it: by clicking the status item, or through a test-only launch argument?

## Saved Data Review

- Does anything besides `HabitStore` read or write the file?
- What does a build one version older do with the new file?
- Is there a fixture test for every earlier `formatVersion`?
