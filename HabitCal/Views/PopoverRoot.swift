import SwiftUI

/// The popover's content: one screen at a time.
struct PopoverRoot: View {
    let model: AppModel

    var body: some View {
        Group {
            switch model.screen {
            case .list: HabitListScreen()
            case .settings: SettingsScreen()
            }
        }
        .frame(width: 330)
        .environment(model)
    }
}
