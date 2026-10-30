/// The first day of the week: Sunday or Monday (T-002 B.12–B.15).
public enum WeekStart: String, Sendable, CaseIterable {
    case sunday
    case monday

    /// 1 for Sunday, 2 for Monday, matching Foundation's weekday numbers.
    public var weekday: Int {
        self == .sunday ? 1 : 2
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
}
