/// Tooltips and spoken labels for habit rows (T-003 §5, E.8).
public enum HabitLabels {
    /// "Oct 5 · done".
    public static func stripTooltip(_ day: Day, _ state: StripDay) -> String {
        let date = "\(MonthNames.name(of: day.month).prefix(3)) \(day.day)"
        switch state {
        case .done: return "\(date) · done"
        case .missed: return "\(date) · missed"
        case .notScheduled, .futureNotScheduled: return "\(date) · not scheduled"
        case .future, .blank: return date
        }
    }

    /// "October 5, done": the strip's spoken value for the focused day.
    public static func stripSpoken(_ day: Day, _ state: StripDay) -> String {
        let date = "\(MonthNames.name(of: day.month)) \(day.day)"
        switch state {
        case .done: return "\(date), done"
        case .missed: return "\(date), missed"
        case .notScheduled, .futureNotScheduled: return "\(date), not scheduled"
        case .future, .blank: return date
        }
    }

    public static func doneButtonSpoken(name: String, dueToday: Bool, doneToday: Bool) -> String {
        guard dueToday else { return "\(name), not scheduled today" }
        return doneToday ? "\(name), done today" : "\(name), not done today"
    }

    public static func doneButtonTooltip(dueToday: Bool, doneToday: Bool) -> String {
        guard dueToday else { return "Not scheduled today" }
        return doneToday ? "Done today — click to undo" : "Mark done today"
    }
}
