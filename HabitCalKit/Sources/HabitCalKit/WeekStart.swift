/// The first day of the week: Sunday or Monday (T-002 B.12–B.15).
public enum WeekStart: String, Sendable, CaseIterable {
    case sunday
    case monday

    /// 1 for Sunday, 2 for Monday, matching Foundation's weekday numbers.
    public var weekday: Int {
        self == .sunday ? 1 : 2
    }

    /// The seven weekdays (1 = Sunday … 7 = Saturday) in column order: the calendar's columns and
    /// the habit form's day buttons (T-002 B.15).
    public var orderedWeekdays: [Int] {
        (0..<7).map { (weekday - 1 + $0) % 7 + 1 }
    }

    /// Maps the Mac's first weekday (`Calendar.firstWeekday`, 1 = Sunday) to the two choices
    /// HabitCal offers: Monday stays Monday, and every other day becomes Sunday.
    public static func fromMac(firstWeekday: Int) -> WeekStart {
        firstWeekday == 2 ? .monday : .sunday
    }

    /// The week start in effect: the user's override if there is one, otherwise the Mac's.
    public static func resolve(override: WeekStart?, mac: WeekStart) -> WeekStart {
        override ?? mac
    }

    /// The override after the user picks `picked` in Settings (T-002 B.13). Picking the Mac's own day
    /// while following the Mac isn't an override, so a later change on the Mac still takes effect.
    /// Once overridden, every explicit pick sticks; only "Use Mac setting" removes it.
    public static func overrideAfterPicking(_ picked: WeekStart, current: WeekStart?, mac: WeekStart) -> WeekStart? {
        if current == nil && picked == mac {
            return nil
        }
        return picked
    }
}
