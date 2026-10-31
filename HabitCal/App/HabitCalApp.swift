import SwiftUI

/// The app: one menu bar extra holding the popover's screens, opened flush under the menu bar like
/// Apple's own extras (D-009, T-029).
@main
struct HabitCalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra {
            PopoverRoot(model: delegate.model)
                .background(PanelWindowHook { [panel = delegate.panel] window in panel.attach(window) })
        } label: {
            MenuBarLabel(model: delegate.model)
        }
        .menuBarExtraStyle(.window)
    }
}
