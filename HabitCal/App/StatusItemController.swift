import AppKit

/// Owns the menu bar item and forwards its clicks.
@MainActor
final class StatusItemController: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let onClick: (NSStatusBarButton) -> Void

    init(onClick: @escaping (NSStatusBarButton) -> Void) {
        self.onClick = onClick
        super.init()
        guard let button = item.button else { return }
        button.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "HabitCal")
        button.setAccessibilityIdentifier("HabitCalStatusItem")
        button.target = self
        button.action = #selector(clicked(_:))
    }

    @objc private func clicked(_ sender: NSStatusBarButton) {
        onClick(sender)
    }
}
