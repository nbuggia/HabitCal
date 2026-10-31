import SwiftUI

/// The popover's content: one screen at a time.
struct PopoverRoot: View {
    /// Wide enough for the habit rows and the leaderboard's tabs. The calendar grid is narrower and
    /// centered, with small gutters (T-009, T-020).
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
        .id(model.openGeneration)
        .frame(width: Self.width)
        .environment(model)
    }
}
