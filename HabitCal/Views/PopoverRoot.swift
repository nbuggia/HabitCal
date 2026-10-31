import SwiftUI

/// The popover's content: one screen at a time.
struct PopoverRoot: View {
    /// The calendar grid (236 pt) plus the screens' 12 pt padding, so the grid's edges line up with
    /// the habit rows (T-009).
    static let width: CGFloat = 260

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
        .frame(width: Self.width)
        .environment(model)
    }
}
