---
name: Menu bar extra
description: Replace NSStatusItem + NSPopover with SwiftUI MenuBarExtra (.window)
task: T-029
rigor: Complex
trigger: "structure: replaces the menu bar component and the app's entry point (ARCHITECTURE.md, D-005 → D-009); risky ground: focus and Esc in a Dock-less app (FM-006)"
date: 2026-10-30
review iteration: 2
status: Approved
---

# Tech Design: Menu Bar Extra

## 1. Context

The customer wants HabitCal to open like Apple's menu bar extras: flush under the menu bar, no arrow, a solid background, a steady icon highlight (spec B.1). An `NSPopover` can't do that. D-009 (2026-10-30) switches to SwiftUI's `MenuBarExtra` with `.window` style, on the strength of the T-029 spike (`spike/README.md`), which proved on the customer's Mac (macOS 27.0.1): the look; Esc closes it natively; code can close it cleanly with `cancelOperation`; `window.close()`/`orderOut` desync it; the window's occlusion notification reports every open; the label redraws.

## 2. Goals / Non-Goals

Goals:

- B.1: open flush, no arrow, solid, steady highlight, from a real click on the icon.
- B.2–B.7 unchanged: closing, reset on open, Esc one level at a time, closing after the website link, ⌘Q, the date icon and its midnight updates, single instance, Edit commands, keyboard input.
- Less code than today: `StatusItemController`, `PopoverController`, `PopoverHostingController`, and `main.swift` go away.
- The existing UI suite passes with only its helper changed.

Non-goals:

- Changing any screen (spec §3). The screens are already plain SwiftUI views under `PopoverRoot`.
- Opening the panel from code. Nothing needs it, and the spike showed `MenuBarExtra` ignores synthetic clicks.
- A custom NSPanel (rejected in D-009).

## 3. Open Questions

- Does XCUITest's `click()` on the status item open a `MenuBarExtra`? Its clicks are real mouse events, unlike the spike's synthetic ones, so it should. Proven in slice 1 by running one UI test; if it fails, FM-008's fallback applies (a Debug launch argument that opens it is impossible, per the spike, so the fallback would be manual checks for the journeys).
- Does an accessibility identifier on the label reach the status item (`app.statusItems["HabitCalStatusItem"]`)? Unknown. The helper uses `app.statusItems.firstMatch` instead (the app has one status item), so the answer doesn't matter.
- Does SwiftUI's App lifecycle keep our hand-built `NSApp.mainMenu` (⌘Q, Edit)? Unknown. SwiftUI installs its own default main menu, which includes Quit (⌘Q) and the Edit commands, so `MainMenu.install()` is likely redundant. Slice 1 checks both by test (`testCommandQQuitsWhilePopoverIsOpen`) and manual check (copy and paste in the form); `MainMenu` is deleted only if both pass without it.

## 4. Requirements

### Spec Review

| Source | Direct claim | Changes it? |
| ------ | ------------ | ----------- |
| T-029 spec B.1 | "open the panel flush under the menu bar, without an arrow, and highlight the icon until it closes" | New |
| T-002 B.4 / T-012 B.2 / T-022 B.7 (spec B.3) | every open starts on the list, current month, today; folded row closed | No: same `resetForOpen()`, new trigger |
| T-002 B.5, T-016 B.6 (spec B.4) | Esc backs out one level; closes from the list | No: new mechanism (§6) |
| T-002 B.18 (spec B.5) | the website link closes the popover | No: new mechanism |
| T-002 E.2 (spec B.6) | a second copy keeps a single icon | No: new mechanism |
| T-021 | hover state cleared on reopen via `openGeneration` | No: still bumped by `resetForOpen()` |
| ARCHITECTURE.md | "D-005: NSStatusItem + NSPopover"; `App/` holds StatusItemController, PopoverController, PopoverHostingController | Yes: rewritten at close |
| CONVENTIONS.md, Popover | "Handle Esc in `AppModel.escape()`, one level per press… Esc reaches `cancelOperation`" | Yes: the mechanism line changes; the rule (one level per press, in `escape()`) stays |
| FM-006 | "Route Esc through `cancelOperation` on the hosting controller" | Yes: recommendation updated at close |
| CONTRACTS.md | habits.json only | No relevant claims |

## 5. Current System Audit

| Concern | Source evidence | Current behavior / gap |
| ------- | --------------- | ---------------------- |
| Entry point | `main.swift`: `NSApplication.shared`, `AppDelegate`, `app.run()` | AppKit lifecycle; `MenuBarExtra` needs a SwiftUI `App` |
| Model creation | `AppDelegate.applicationDidFinishLaunching`: options, store, seed, `AppModel`, login default | Created after launch; a SwiftUI `App` builds its scenes earlier |
| Single instance | `AppDelegate`: terminates if an earlier copy runs | Runs before the status item exists |
| Status item and icon | `StatusItemController.show(day)`: `MenuBarIcon.image(for:)`, label "HabitCal, <spoken date>", identifier `HabitCalStatusItem` | Driven by `DayWatcher.onTodayChange` |
| Open | `PopoverController.toggle`: reopen guard, `resetForOpen()`, `NSApp.activate()`, `show`, highlight (T-027), `focusHostingView()` | |
| Close in code | `model.closePopover` → `popover.performClose` (used by `SettingsScreen` website link) | |
| Esc | `PopoverHostingController.cancelOperation` → `model.escape()`; `.closePopover` closes | Relies on first responder in the chain: `screenDidChange`/`listDidHideRows` refocus (FM-006) |
| Edit and ⌘Q | `MainMenu.install()` sets `NSApp.mainMenu` | |
| Day changes | `DayWatcher` sets `model.today`, calls `onTodayChange` | |
| UI tests | `HabitCalUITestCase.popover` = `app.popovers.firstMatch`; `statusItem` = `app.statusItems["HabitCalStatusItem"]` | 12 uses of `statusItem`; every lookup goes through `popover` |

| Failure mode | Applicable / Not applicable / Checked—no issue / Accepted risk | Evidence |
| ------------ | -------------------------------------------------------------- | -------- |
| FM-001 stale date | Applicable | The label must redraw on `model.today`; it's a SwiftUI view observing the model (spike Q4 proved a label redraws). `DayWatcher` unchanged. Test: `testMenuBarIconShowsTodaysDate` + midnight manual test |
| FM-002 instants vs days | Not applicable | No date handling changes |
| FM-003 saving destroys data | Not applicable | No storage changes; seed write moves unchanged |
| FM-004 UI off main actor | Applicable | Occlusion and key-monitor callbacks arrive on the main queue; handlers use `MainActor.assumeIsolated`, as `DayWatcher` does |
| FM-005 Mac settings changes | Checked — no issue | `DayWatcher` unchanged |
| FM-006 focus and dismissal | Applicable | `MenuBarExtra` activates and keys its window (spike: `didBecomeKey` on open). Esc: a local key monitor in front of the native close (§6). Typing in the form: `testTypingInTheNameFieldKeepsFocus` |
| FM-007 real date in tests | Checked — no issue | Launch options unchanged |
| FM-008 UI tests can't reach the status item | Applicable | Open Question 1; proven in slice 1 |
| FM-009 login item | Not applicable | Unchanged |
| FM-010 text field values | Not applicable | Unchanged |
| FM-011 SVG gradients | Not applicable | Icon is drawn in code |

## 6. Proposed Design

```
HabitCalApp (@main, SwiftUI App)
 ├─ @NSApplicationDelegateAdaptor AppDelegate ── init: a later copy exits first; then AppModel, DayWatcher, PanelController
 └─ MenuBarExtra { PopoverRoot } label: { MenuBarLabel }   .window style
        PopoverRoot ── .background(PanelWindowHook) ── reports its NSWindow to PanelController:
                         reset after a real close; model.closePopover; Esc key monitor; close on app deactivation
```

- **`HabitCalApp`** (`HabitCal/App/HabitCalApp.swift`, replaces `main.swift`): `@main`; one `MenuBarExtra` scene, `.menuBarExtraStyle(.window)`, content `PopoverRoot(model:)`, label `MenuBarLabel(model:)`. No `isInserted` binding: it would opt into a user-removable item, which a relaunch couldn't bring back (review 3).
- **`AppDelegate`**: the first statement of its `init` is the single-instance check (E.2): a later copy calls `exit(0)` there, before any model, seed write, or scene, whichever order SwiftUI creates the delegate and the App in (review 9). Then it builds `LaunchOptions`, the store, the seed, `AppModel`, `DayWatcher`, and `PanelController` in `init`, because SwiftUI builds the scenes before `applicationDidFinishLaunching`. `applicationDidFinishLaunching` applies the login default (a write, after the single-instance check). `DayWatcher`'s `onTodayChange` callback is dropped: the label observes `model.today`.
- **`MenuBarLabel`** (`HabitCal/MenuBar/MenuBarLabel.swift`): `Image(nsImage: MenuBarIcon.image(for: model.today))` with `.accessibilityLabel("HabitCal, \(MonthNames.spokenDate(model.today))")` and the identifier. `MenuBarIcon` is unchanged.
- **`PanelWindowHook`** (`HabitCal/App/PanelWindowHook.swift`): an `NSViewRepresentable` in `PopoverRoot`'s background whose view reports its `window` each time it moves into one. `PanelController` (`HabitCal/App/PanelController.swift`, `@MainActor`, kept by `AppDelegate`) then, re-registering if the window object is new (nothing proves it's reused between opens):
  - observes `NSWindow.didChangeOcclusionStateNotification` for **that window object** (no class-name matching). When the window becomes not visible and `window.isVisible` is false, it records a real close; on the next change to visible after a real close it calls `model.resetForOpen()` (B.3). The flag keeps a display wake from resetting a half-typed form (review 4). The flag starts true, and when the hook reports a window that is already visible while it's true, `PanelController` resets right then: on the first open the hook can arrive after the first "visible" notification, which would otherwise leave a launch-time month showing (review 8).
  - sets `model.closePopover = { window.firstResponder?.tryToPerform(#selector(NSResponder.cancelOperation(_:)), with: nil) }` (B.5), from the first responder exactly as the spike proved clean (review 2). Slice 1 checks it with the form's text field focused (via the deactivation close below); if a field editor swallows it, end editing first with `window.makeFirstResponder(nil)` and send it again.
  - observes `NSApplication.didResignActiveNotification` and calls `closePopover` while the window is visible (B.2, B.5): the spike showed `MenuBarExtra` only resigns key when another app activates, so switching apps and opening the website link both close through here (review 1). The website link's explicit `closePopover()` call stays.
  - installs one local `keyDown` monitor for Esc (keyCode 53) for events whose `window` is the panel: if the first responder is an `NSTextView` with marked text (an input method composing), the event passes through untouched (review 6); else if `model.escape()` returns `.handled`, the event is consumed; if `.closePopover`, it's passed on and `MenuBarExtra` closes natively (B.4). The monitor runs before the field editor and before `.keyboardShortcut(.cancelAction)`, so the form's Cancel shortcut never doubles it. Local monitors don't run during menu tracking, so the right-click menu keeps its own Esc.
- **Removed:** `main.swift`, `StatusItemController`, `PopoverController`, `PopoverHostingController`, T-027's manual highlight. `AppModel.screenDidChange` and `listDidHideRows` are removed only if `testEscStillClosesAfterFoldingAwayTheFocusedStrip` and `testEscapeLeavesSettingsThenClosesPopover` pass without them: the back-out step doesn't need the first responder, but the native close on `.closePopover` does go through the responder chain (FM-006, review 5). If either fails, `PanelController` keeps them, refocusing the window's content view.
- **`MainMenu`:** kept until slice 1 shows SwiftUI's default menu provides ⌘Q and Edit (Open Question 3); then deleted.

End-to-end: click icon → `MenuBarExtra` shows its window and highlights the icon → occlusion "visible" → `resetForOpen()` (list, month, today, folded row closed, hover cleared) → user selects Settings → presses Esc → monitor → `escape()` → `.handled` (back to list), event consumed → Esc again → `.closePopover` → event passes → native close, icon highlight clears. Failure: if the window can't be found (hook never fires), `closePopover` stays a no-op and reset doesn't run; the next UI test that opens twice catches it (`testPopoverOpensOnCurrentMonthAndListAndClosesOnSecondClick`).

| New state | Owner | Lifetime | Persist? | Why |
| --------- | ----- | -------- | -------- | --- |
| Panel window reference (weak), occlusion and resign-active observers, key monitor | `PanelController` | App | No | Reset on open, close in code, Esc |
| `closedSinceReset` | `PanelController` | App | No | Reset only after a real close (review 4) |

| Operation | Triggers | Caller | Boundary | Handler/event | Registration | Consumer/state | Restore/cleanup | Test | Evidence |
| --------- | -------- | ------ | -------- | ------------- | ------------ | -------------- | --------------- | ---- | -------- |
| Open | Click on icon | User | SwiftUI ↔ AppKit window | Occlusion → `resetForOpen()` | Observer added when the hook reports the window | `AppModel` screen, month, selection, folded row, `openGeneration` | Observer lives with the app | `testPopoverOpensOnCurrentMonthAndListAndClosesOnSecondClick`, `testReopeningSelectsToday`, `testHabitsNotDueTodayFoldIntoARow` (reopen part) | spike Q3 |
| Close by Esc | Esc | User | AppKit key event | Monitor → `escape()` | Monitor installed with the observer | screen | Monitor lives with the app | `testEscapeLeavesSettingsThenClosesPopover`, `testEscapeInFormReturnsToList`, `testEscFromLeaderboardReturnsToList`, `testEscStillClosesAfterFoldingAwayTheFocusedStrip` | spike Q2 (native) |
| Close in code | Website link | `SettingsScreen` | AppKit responder chain | `cancelOperation` from the window's first responder | `closePopover` set when the hook reports the window | window | — | manual (opens a browser; UI tests can't follow) | spike Q2 (`cancelOperation`) |
| Close by click / outside | User | `MenuBarExtra` | — | native | — | — | — | `…ClosesOnSecondClick`; manual for outside | spike |
| Close on app switch | Another app activates | AppKit | `NSApplication` notification | `didResignActive` → `closePopover` | Observer added with the window | window | — | manual (⌘-Tab, with the form's text field focused) | review 1 |
| Icon redraw | Midnight, wake, clock | `DayWatcher` | — | `model.today` → `MenuBarLabel` | Observation | label | — | `testMenuBarIconShowsTodaysDate`; midnight manual test | spike Q4 |
| Single instance | Second launch | `AppDelegate.init` | Launch Services | `exit(0)` before the model and scenes | — | — | — | manual (existing E.2 manual step) | review 3 |
| Quit | Quit button, ⌘Q | User | `NSApp.terminate` | — | — | — | — | `testQuitButtonQuits`, `testCommandQQuitsWhilePopoverIsOpen` | |

| Guarantee | Mechanism | Owner | Linearization point | Failure behavior | Proof |
| --------- | --------- | ----- | ------------------- | ---------------- | ----- |
| Every open starts reset | Occlusion visible after a real close → `resetForOpen()` | `PanelController` | The occlusion notification, delivered before the first frame the user can act on | If late, the old screen flashes for a frame | Reopen UI tests |
| A display wake doesn't reset an open panel | `closedSinceReset` set only when `isVisible` is false | `PanelController` | The not-visible notification | — | Manual: open the form, sleep the display, wake |
| Esc backs out one level | Key monitor consumes unless `escape()` says close | `PanelController` | The monitor, before the field editor and responder chain | — | Esc UI tests |
| Code close doesn't desync | `cancelOperation`, never `close()`/`orderOut` | `PanelController` | — | Next click swallowed if violated | spike log; manual |

| Boundary | Concurrent event | Invariant | Linearization point | Recovery |
| -------- | ---------------- | --------- | ------------------- | -------- |
| Occlusion vs midnight | `DayWatcher` sets `today` while opening | `resetForOpen()` uses the current `today` | Main actor serializes both | None needed |
| Esc while form text field edits | Field editor would take Esc | Monitor sees it first | Local monitor | — |
| Esc while an input method composes | Esc should cancel the composition | Monitor passes it through when `hasMarkedText()` | Local monitor | — |

### Red Flags Audit

| Red flag | Present? | If present, why acceptable |
| --- | --- | --- |
| Shallow module | No | `PanelController` hides window discovery, observation, Esc, and closing behind `AppModel` hooks the views already use |
| Information leakage | No | Views keep calling `model.closePopover()` and `model.escape()`; nothing knows about `MenuBarExtra` |
| Temporal decomposition | No | |
| Pass-through method | No | |

## 7. Interface Contract

| Interface | Inputs | Output | Errors | Async? |
| --------- | ------ | ------ | ------ | ------ |
| `MenuBarExtra(content:label:)` + `.menuBarExtraStyle(.window)` | views | scene | — | main actor |
| `NSWindow.didChangeOcclusionStateNotification` | object: the panel window | — | — | posted on main; observed on `.main` |
| `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` | handler | token | — | main |
| `NSResponder.tryToPerform(_:with:)` with `cancelOperation(_:)`, from the window's first responder | — | Bool | false if nobody handles it | main |
| `NSApplication.didResignActiveNotification` | — | — | — | posted on main; observed on `.main` |
| `AppModel.resetForOpen()`, `escape()`, `closePopover` | unchanged | | | main actor |

## 8. Data Model & Persistence

None. habits.json and UserDefaults are untouched.

## 9. Capabilities & Security

None. No entitlements change; the sandbox and the no-network rule (D-007) are unaffected.

## 10. macOS Versions and Appearance

| Variant | Difference from baseline | Verified how |
| ------- | ------------------------ | ------------ |
| macOS 15 (deployment target) | `MenuBarExtra` `.window` exists since 13; occlusion notification since 10.9. The look is the system's, per OS | Not verifiable here (the Mac runs 27.0.1); accepted risk, noted for T-005's release check |
| Dark mode, Increase Contrast | The system draws the panel background and highlight | Manual: menu-bar manual tests in both appearances |
| VoiceOver | Status item label unchanged; panel contents unchanged | `testMenuBarIconShowsTodaysDate`; existing VoiceOver manual test |
| Intel | None | — |

## 11. Alternatives / Reuse / Proportionality

| Checked | Stdlib / native / existing dep / new dep | Covers? | Why not | Ceiling / upgrade path |
| ------- | ---------------------------------------- | ------- | ------- | ---------------------- |
| `MenuBarExtra` `.window` (chosen) | native | Yes, with the hook for reset/close/Esc | — | If a future macOS breaks `cancelOperation` closing, fall back to a custom panel |
| Custom `NSPanel` under `NSStatusItem` | native | Yes | Rebuilds positioning, material, dismissal, highlight by hand (D-009) | — |
| Keep `NSPopover` | native | No | Arrow, gap, glass (spec B.1) | — |
| `MenuBarExtraAccess` package | new dep | Yes | PRD: no dependencies; the spike found the one technique we need | — |
| `onAppear` for reset | native | Partly | Fired on both opens in the spike, but SwiftUI may keep the view alive between opens; the occlusion notification is the window's own signal | — |
| `didBecomeKey` for reset | native | No | Also fires when the user clicks back into an open panel (spike) | — |
| `MenuBarExtra(isInserted:)` for single instance | native | Yes | Opts into a user-removable item a relaunch couldn't restore | — |

| Rare case | Cost to support | Requirement change that deletes it | Recommend |
| --------- | --------------- | ---------------------------------- | --------- |
| Opening from code (e.g. a global hotkey, BACKLOG) | Impossible with `MenuBarExtra` (spike) | Not needed in v1 | Accept; revisit with the hotkey backlog item |

## 12. Implementation Slicing Strategy

1. **Slice 1, the switch:** `HabitCalApp`, `AppDelegate` init, `MenuBarLabel`, `PanelWindowHook`/`PanelController`, removals; the UI tests: the helper's `popover` finds the panel by identifier `habitcalPanel` (set on `PopoverRoot` with `.accessibilityElement(children: .contain)`, so it isn't dropped or passed to children), `statusItem` becomes `app.statusItems.firstMatch`, and `testStatusItemOpensAndClosesPopover`'s direct `app.popovers` use changes too (review 7). Demo: the app opens flush; run `MenuBarUITests` (needs the customer's screen); check the code close with the form focused (⌘-Tab). Answers Open Questions 1–3.
2. **Slice 2, the full suite and cleanup:** run every UI test; delete `MainMenu` if Open Question 3 allows; manual checks (website link closes, outside click, app switch, single instance, copy/paste, dark mode).

Two slices, so no slicing plan (development.md).

## 13. Testing Strategy

| Test | Kind | Spec rules proved | Regression prevented |
| ---- | ---- | ----------------- | -------------------- |
| `testPopoverOpensOnCurrentMonthAndListAndClosesOnSecondClick` | UI | B.1 (opens), B.2, B.3 | Reset not wired to the new open |
| `testReopeningSelectsToday`, `testHabitsNotDueTodayFoldIntoARow` | UI | B.3 | Selection or folded row survives a reopen |
| `testEscapeLeavesSettingsThenClosesPopover`, `testEscapeInFormReturnsToList`, `testEscFromLeaderboardReturnsToList`, `testEscStillClosesAfterFoldingAwayTheFocusedStrip` | UI | B.4 | Native Esc closing from Settings or the form |
| `testQuitButtonQuits`, `testCommandQQuitsWhilePopoverIsOpen` | UI | B.5 (quit) | SwiftUI main menu dropping ⌘Q |
| `testMenuBarIconShowsTodaysDate` | UI | B.6 (icon) | Label lost its spoken date |
| `testTypingInTheNameFieldKeepsFocus` and the form tests | UI | B.7 | Panel not key (FM-006) |
| Whole existing UI suite | UI | B.2–B.7 | Anything the helper change breaks |
| Look: flush, no arrow, solid, steady highlight; light and dark | manual (customer) | B.1 | — |
| Website link closes the panel, and the next click opens it | manual | B.5 | `close()`-style desync |
| Outside click closes it; ⌘-Tab closes it with the form's text field focused, and the next click opens it | manual | B.2, B.5 | Deactivation not closing; field editor swallowing the close |
| Display sleep and wake with the form open keeps the draft | manual | B.3 | Reset on a wake |
| Esc while composing with an input method cancels the composition, not the form | manual | B.4, B.7 | Monitor stealing IME Esc |
| Second copy keeps one icon | manual (existing) | B.6 | |
| Copy and paste in the form | manual | B.6 | Edit menu lost |
| Midnight with the panel closed and open | manual (existing) | B.6 | FM-001 |

## 14. Rollout

Direct ship, no flag.

## 15. Reviewer Feedback

| \#  | Finding | Severity | Cost to accept | Decision | Rationale | Next step | Arch? | Source |
| --- | ------- | -------- | -------------- | -------- | --------- | --------- | ----- | ------ |
| 1 | Switching apps likely doesn't close a `MenuBarExtra` (the spike's link only resigned key) | MAJOR | Panel stays over other apps | ACCEPT | Spike evidence | Resign-active close in `PanelController` | Yes | Pass 1 |
| 2 | Code close from `contentView` was never proven; the spike used the first responder | MAJOR | Website link silently fails to close | ACCEPT | Use what the spike proved | First responder; slice 1 check with the form focused | No | Pass 1 |
| 3 | `isInserted` may make the icon user-removable | QUESTION | Icon lost until a fix | ACCEPT | Simpler without it | `exit(0)` in `HabitCalApp.init` | Yes | Pass 1 |
| 4 | Occlusion visible on display wake would reset a half-typed form | MINOR | Lost draft | ACCEPT | Cheap flag | `closedSinceReset` | No | Pass 1 |
| 5 | Removing the refocus hooks is only half justified | MINOR | Esc dead after a fold | ACCEPT | | Remove only if the Esc tests pass | No | Pass 1 |
| 6 | Key monitor steals Esc from an input method | MINOR | Draft discarded while composing | ACCEPT | | Pass through with marked text | No | Pass 1 |
| 8 | The first open can miss its reset if the hook arrives after the first "visible" notification | MINOR | Launch-time month shown after a month boundary | ACCEPT | | Reset when the hook reports an already-visible window | No | Pass 2 |
| 9 | Single-instance check in `HabitCalApp.init` may run after `AppDelegate.init` builds the model | MINOR | A later Debug copy writes its seed file | ACCEPT | Order is undocumented | First statement of `AppDelegate.init` | No | Pass 2 |
| 10 | Three spots still said content view / `isInserted` | MINOR | Wrong method in the lasting docs | ACCEPT | | Edited §6, §7, §16 | No | Pass 2 |
| 7 | One more test uses `app.popovers`; a `Group` identifier may be dropped; the window may be new per open | MINOR | Broken tests; observers on a dead window | ACCEPT | | Per slice 1 | No | Pass 1 |

## 16. Lasting Changes

| Change | Goes to |
| ------ | ------- |
| The menu bar is a `MenuBarExtra` (`.window`) scene in `HabitCalApp`; `PanelController` resets on open (occlusion), closes in code with `cancelOperation`, and handles Esc with a key monitor; the label observes `model.today` | ARCHITECTURE.md (App/, The Popover) |
| Close the panel in code only with `cancelOperation` from the window's first responder, never `close()`/`orderOut` | CONVENTIONS.md, Popover; FM-006 recommendation |
| Esc rule: one level per press in `AppModel.escape()`, via the key monitor | CONVENTIONS.md, Popover (mechanism line) |
| `MenuBarExtra` can't be opened from code | ARCHITECTURE.md; FM-008 note (UI tests open it by clicking) |
| UI tests find the panel by `habitcalPanel` and the icon by `statusItems.firstMatch` | TESTING.md; FM-008's detection line (names `HabitCalStatusItem` today) |
| `MenuBarExtra` doesn't close when another app activates; `PanelController` closes it on resign-active | ARCHITECTURE.md; FM-006 |
| Rejected open signals: `didBecomeKey` (fires on clicking back in), `onAppear` (view may outlive a close); synthetic clicks and `performClick` don't open it | ARCHITECTURE.md (with the occlusion choice) |
| Single instance: the first statement of `AppDelegate.init` exits a later copy; not `isInserted` | ARCHITECTURE.md |
| The model is built in `AppDelegate.init` because SwiftUI builds scenes before `applicationDidFinishLaunching` | ARCHITECTURE.md |
| D-009 | Already logged |
