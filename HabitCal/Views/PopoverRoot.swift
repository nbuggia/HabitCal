import SwiftUI

/// The popover's content: one screen at a time.
struct PopoverRoot: View {
    /// One 200 pt column with `margin` on each side. The calendar's first and last date squares sit on
    /// the column's edges, and every screen's content lines up with them (T-024).
    static let width: CGFloat = 232
    static let margin: CGFloat = 16

    let model: AppModel

    var body: some View {
        Group {
            switch model.screen {
            case .list: HabitListScreen()
            case .settings: SettingsScreen()
            case .form: HabitFormScreen()
            case .leaderboard: LeaderboardScreen()
            }
        }
        .id(model.openGeneration)
        .frame(width: Self.width)
        .environment(model)
    }
}
