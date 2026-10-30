import HabitCalKit
import Observation

/// The app's state, shared by the menu bar and every popover screen.
@MainActor
@Observable
final class AppModel {
    /// Today on the Mac's calendar. Only `DayWatcher` sets it.
    var today: Day

    init(today: Day) {
        self.today = today
    }
}
