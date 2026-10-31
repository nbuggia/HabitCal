import SwiftUI

/// The popover's content: one screen at a time.
struct PopoverRoot: View {
    /// One 200 pt column with `margin` on each side. The calendar's first and last date squares sit on
    /// the column's edges, and every screen's content lines up with them (T-024).
    static let width: CGFloat = 232
    static let margin: CGFloat = 16

    let model: AppModel

    /// The list screen's height when last shown. Every other screen is at least this tall, so the panel
    /// keeps its size as you move between screens (T-032). A screen with more content grows past it.
    @State private var listHeight: CGFloat = 0

    var body: some View {
        Group {
            switch model.screen {
            case .list:
                HabitListScreen()
                    .onGeometryChange(for: CGFloat.self) {
                        $0.size.height
                    } action: {
                        listHeight = $0
                    }
            case .settings: SettingsScreen().frame(minHeight: listHeight, alignment: .top)
            case .form: HabitFormScreen().frame(minHeight: listHeight, alignment: .top)
            case .leaderboard: LeaderboardScreen().frame(minHeight: listHeight, alignment: .top)
            }
        }
        .id(model.openGeneration)
        .frame(width: Self.width)
        .environment(model)
        // UI tests find the MenuBarExtra panel by this (T-029); `.contain` keeps it from being
        // dropped or passed down to the children.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("habitcalPanel")
    }
}
