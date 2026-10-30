import HabitCalKit
import Observation

/// The popover's screens. T-003 adds the habit form.
enum Screen: Equatable {
    case list
}

/// What Esc did: handled inside the popover, or nothing left to back out of, so close it.
enum EscapeResult {
    case handled
    case closePopover
}

/// The app's state, shared by the menu bar and every popover screen.
@MainActor
@Observable
final class AppModel {
    /// Today on the Mac's calendar. Only `DayWatcher` sets it.
    var today: Day
    /// The Mac's first day of the week, mapped to Sunday or Monday. Only `DayWatcher` sets it.
    var macWeekStart: WeekStart
    private(set) var displayedMonth: Month
    private(set) var screen: Screen = .list

    init(today: Day, macWeekStart: WeekStart) {
        self.today = today
        self.macWeekStart = macWeekStart
        displayedMonth = Month(today)
    }

    var weekStart: WeekStart {
        WeekStart.resolve(override: nil, mac: macWeekStart)
    }

    var gridDays: [Day] {
        MonthGrid.days(in: displayedMonth, weekStart: weekStart)
    }

    /// Every open starts from the habit list and the current month (T-002 B.4).
    func resetForOpen() {
        screen = .list
        displayedMonth = Month(today)
    }

    func showPreviousMonth() {
        displayedMonth = displayedMonth.previous
    }

    func showNextMonth() {
        displayedMonth = displayedMonth.next
    }

    func showToday() {
        displayedMonth = Month(today)
    }

    /// Esc backs out one level at a time, and closes the popover from the list (T-002 B.5).
    func escape() -> EscapeResult {
        switch screen {
        case .list: .closePopover
        }
    }
}
