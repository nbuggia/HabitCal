# Artwork

## App icon (proposal, not yet in the app)

`app-icon-proposal-1024.png` (with 512, 128, and 32 px copies to judge small sizes): a white calendar page with a green header, binder rings, and a check mark, on Apple's macOS icon grid. It's the icon Finder, Downloads, and the About box would show; the menu bar keeps its tear-off date icon (D-008).

`render-app-icon.swift` draws it at every size: `swiftc -o render render-app-icon.swift && ./render <output folder>`. Once approved, T-005 puts the sizes into `HabitCal/Assets.xcassets/AppIcon.appiconset`.
