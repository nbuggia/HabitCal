# Spike: can SwiftUI's MenuBarExtra replace the NSPopover?

## Question

D-005 rejected `MenuBarExtra` because it "has no supported way to close itself programmatically or to know when it opens". The customer wants HabitCal to open like Apple's menu bar extras (flush, no arrow, solid, steady icon highlight), which `MenuBarExtra` with `.window` style does natively. On macOS 27.0.1 (the customer's Mac):

1. Does the window close by itself when a link opens the browser?
2. Can Esc close it, natively or by our code, without the "click the icon twice" desync?
3. Does `NSWindow.didBecomeKeyNotification` fire on every open (to reset to today and the list)? Does `onAppear`?
4. Does the menu bar label redraw when the model changes (the icon at midnight)?

Build: `./build.sh <dir>`, run `open <dir>/MBXSpike.app --args <log file>`. Every event goes to the log file.

## Answer

**Yes: `MenuBarExtra` (`.window` style) can do everything D-005 needed** (run with the customer on their Mac, 2026-10-30; log excerpts below).

- **Look (customer):** flush under the menu bar, no arrow, a solid background like Apple's Now Playing, and a steady icon highlight while open.
- **Q4, icon redraw (customer):** the label redraws when the model changes.
- **Q3, knowing when it opens:** `NSWindow.didChangeOcclusionStateNotification` with `.visible` fired on every open, and `onAppear` fired on both real opens. `didBecomeKey` is not usable: it also fires when the user clicks back into an open window.
- **Q1, link:** the window does **not** close when a link opens the browser (it only resigns key). HabitCal must close it itself.
- **Q2, closing:**
  - Esc pressed by the user closes it natively, and the icon's highlight clears (customer: "esc closes perfectly").
  - **Closing in code works cleanly by sending `cancelOperation(_:)` to the window's first responder, or a synthetic Esc key event to the window**: the next click opened it at once.
  - `window.close()` and `orderOut` close it but leave the icon highlighted and desync SwiftUI's state, so the next click is swallowed (customer saw it; the next opens came 11–13 s later).
  - The status button's `performClick` and synthetic mouse events do nothing: only real clicks open it. HabitCal never needs to open it in code.

Consequences for T-029: close with `cancelOperation`, never `close()`/`orderOut`; reset on the occlusion notification; HabitCal's own Esc rules (back out of the form and Settings first) need a key handler in front of the native Esc, as the spike's local monitor showed is possible. Unproven: whether XCUITest's click on the status item opens it (its clicks are real mouse events, so it should).

```
10:02:48  open #1: will close by window.close()   -> closed; next open 10:03:01 (icon stuck, extra clicks)
10:03:01  open #2: will close by native Esc event -> closed; next open 10:03:05
10:03:05  open #3: will close by orderOut         -> closed; next open 10:03:20 (stuck)
10:03:20  open #4: will close by cancelOperation  -> closed; next open 10:03:23
```
