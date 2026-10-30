/// English names for months and weekdays, shared by the icon, the calendar, and spoken labels.
/// The v1 interface is English whatever the Mac's language (T-002 spec, Assumptions).
public enum MonthNames {
    private static let months = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December",
    ]
    private static let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    /// "October", for month 1–12.
    public static func name(of month: Int) -> String {
        months[month - 1]
    }

    /// "OCT": the three capitals cut out of the icon's header bar.
    public static func abbreviation(of month: Int) -> String {
        String(months[month - 1].prefix(3)).uppercased()
    }

    /// "Thursday", for weekday 1 (Sunday) … 7 (Saturday).
    public static func weekdayName(_ weekday: Int) -> String {
        weekdays[weekday - 1]
    }

    /// "T", for weekday 1 (Sunday) … 7 (Saturday).
    public static func weekdayInitial(_ weekday: Int) -> String {
        String(weekdays[weekday - 1].prefix(1))
    }

    /// "Thursday, October 29".
    public static func spokenDate(_ day: Day) -> String {
        "\(weekdayName(day.weekday)), \(name(of: day.month)) \(day.day)"
    }

    /// "Thursday, October 29, 2026".
    public static func spokenFullDate(_ day: Day) -> String {
        "\(spokenDate(day)), \(day.year)"
    }

    /// A calendar cell's spoken label: "Thursday, October 29, 2026", plus ", today" on today (T-002 E.6).
    public static func spokenCalendarDay(_ day: Day, isToday: Bool) -> String {
        spokenFullDate(day) + (isToday ? ", today" : "")
    }
}
