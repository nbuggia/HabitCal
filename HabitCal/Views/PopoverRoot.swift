import SwiftUI

/// The popover's content: one screen at a time.
struct PopoverRoot: View {
    /// Just wider than the calendar grid, so it has slim side margins (T-007).
    static let width: CGFloat = 280

    let model: AppModel

    var body: some View {
        Group {
            switch model.screen {
            case .list: HabitListScreen()
            case .settings: SettingsScreen()
            case .form: HabitFormScreen()
            }
        }
        .frame(width: Self.width)
        .environment(model)
    }
}
