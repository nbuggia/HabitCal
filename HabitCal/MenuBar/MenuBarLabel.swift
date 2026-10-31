import HabitCalKit
import SwiftUI

/// The menu bar icon: today's tear-off calendar page (D-008). It observes `model.today`, so it redraws
/// when `DayWatcher` moves the date (FM-001).
struct MenuBarLabel: View {
    let model: AppModel

    var body: some View {
        Image(nsImage: MenuBarIcon.image(for: model.today))
            .accessibilityLabel("HabitCal, \(MonthNames.spokenDate(model.today))")
            .accessibilityIdentifier("HabitCalStatusItem")
    }
}
