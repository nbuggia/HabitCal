# Close: T-021 Hover and pressed states

| Item | Landed in |
| --- | --- |
| B.1 hover and pressed highlight on every popover button | `HoverButtonStyle`; docs/manual-tests/habits.md, "Buttons answer the pointer" |
| B.2 disabled buttons dim and don't highlight | `HoverButtonStyle`; same manual test; `testUnreadableDataShowsMessageAndDisablesAdd` (next full run) |
| B.3 actions, labels, shortcuts unchanged | Existing UI suite (next full run) |
| Practice: popover buttons use `.hover` | docs/engineering/CONVENTIONS.md, Popover |
| Review 1: hover stuck after closing under the pointer | `AppModel.openGeneration` + `.id` in `PopoverRoot`; manual step 3 |
| Review 4: no visible keyboard focus | `isFocused` shows the highlight; manual step 4 |
| Review 2, 3: color shift from `.borderless`, double-dimmed disabled buttons | Deferred to the screenshot pass (pickup.md); manual test checks both |
