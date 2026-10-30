import AppKit
import HabitCalKit

/// Owns the menu bar item: draws today's date in it and forwards its clicks.
@MainActor
final class StatusItemController: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let onClick: (NSStatusBarButton) -> Void

    init(onClick: @escaping (NSStatusBarButton) -> Void) {
        self.onClick = onClick
        super.init()
        guard let button = item.button else { return }
        button.setAccessibilityIdentifier("HabitCalStatusItem")
        button.target = self
        button.action = #selector(clicked(_:))
    }

    /// Redraws the icon and its spoken label for `day`.
    func show(_ day: Day) {
        guard let button = item.button else { return }
        button.image = MenuBarIcon.image(for: day)
        button.setAccessibilityLabel("HabitCal, \(MonthNames.spokenDate(day))")
    }

    @objc private func clicked(_ sender: NSStatusBarButton) {
        onClick(sender)
    }
}
