# Artwork

## App icon (proposals, not yet in the app)

Three options, each at 1024, 512, 128, and 32 px, so you can judge small sizes too. Each one is a white calendar page with binder rings, on Apple's macOS icon grid:

- `app-icon-fire-green-*`: green header, orange fire (the app's streak flame).
- `app-icon-fire-orange-*`: orange header, orange fire.
- `app-icon-check-*`: green header, green check mark (the first proposal).

This is the icon Finder, Downloads, and the About box show; the menu bar keeps its tear-off date icon (D-008). The fire is Phosphor's "fire" (MIT), the same glyph as the streak count.

`render-app-icon.swift` draws all three: `swiftc -o render render-app-icon.swift && ./render <output folder>`. Once one is chosen, T-005 puts its sizes into `HabitCal/Assets.xcassets/AppIcon.appiconset`.
