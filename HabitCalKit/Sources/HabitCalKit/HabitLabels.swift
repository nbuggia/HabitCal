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

    public static func doneButtonSpoken(name: String, doneToday: Bool) -> String {
        doneToday ? "\(name), done today" : "\(name), not done today"
    }

    public static func doneButtonTooltip(doneToday: Bool) -> String {
        doneToday ? "Done today — click to undo" : "Mark done today"
    }

    /// The done button's spoken label for the selected day: today reads as before, another day
    /// names it ("Push-ups, done on October 23"), and a future day says it can't be checked off (T-022).
    /// Only habits due on the day are listed (T-036), so there's no not-due wording.
    public static func doneButtonSpoken(name: String, day: Day, today: Day, done: Bool) -> String {
        if day == today { return doneButtonSpoken(name: name, doneToday: done) }
        let date = "\(MonthNames.name(of: day.month)) \(day.day)"
        if day > today { return "\(name), \(date), can't check off a future day" }
        return done ? "\(name), done on \(date)" : "\(name), not done on \(date)"
    }

    /// The done button's tooltip for the selected day (T-022).
    public static func doneButtonTooltip(day: Day, today: Day, done: Bool) -> String {
        if day == today { return doneButtonTooltip(doneToday: done) }
        let date = shortDate(day)
        if day > today { return "Can't check off a future day" }
        return done ? "Done \(date) — click to undo" : "Mark done for \(date)"
    }

    /// Shown in place of the rows when no habit is due on the selected day (T-012 B.3, T-022).
    public static func nothingDue(onToday: Bool) -> String {
        onToday ? "Nothing due today" : "Nothing due that day"
    }

    /// "Oct 23".
    private static func shortDate(_ day: Day) -> String {
        "\(MonthNames.name(of: day.month).prefix(3)) \(day.day)"
    }

    /// "Edit Push-ups": the name button's spoken label.
    public static func editSpoken(name: String) -> String {
        "Edit \(name)"
    }
}
