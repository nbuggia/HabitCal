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

    /// The done button's spoken label for the selected day: today reads as before, another day
    /// names it ("Push-ups, done on October 23"), and a future day says it can't be checked off (T-022).
    public static func doneButtonSpoken(name: String, day: Day, today: Day, due: Bool, done: Bool) -> String {
        if day == today { return doneButtonSpoken(name: name, dueToday: due, doneToday: done) }
        let date = "\(MonthNames.name(of: day.month)) \(day.day)"
        guard due else { return "\(name), not scheduled on \(date)" }
        if day > today { return "\(name), \(date), can't check off a future day" }
        return done ? "\(name), done on \(date)" : "\(name), not done on \(date)"
    }

    /// The done button's tooltip for the selected day (T-022).
    public static func doneButtonTooltip(day: Day, today: Day, due: Bool, done: Bool) -> String {
        if day == today { return doneButtonTooltip(dueToday: due, doneToday: done) }
        let date = shortDate(day)
        guard due else { return "Not scheduled \(date)" }
        if day > today { return "Can't check off a future day" }
        return done ? "Done \(date) — click to undo" : "Mark done for \(date)"
    }

    /// "3 not due today": the folded row under the due habits (T-012 B.2); "that day" on another
    /// selected day (T-022).
    public static func notDueRowTitle(count: Int, onToday: Bool = true) -> String {
        "\(count) not due \(onToday ? "today" : "that day")"
    }

    /// "3 habits not due today".
    public static func notDueRowSpoken(count: Int, onToday: Bool = true) -> String {
        "\(count) \(count == 1 ? "habit" : "habits") not due \(onToday ? "today" : "that day")"
    }

    /// Shown in place of the rows when no habit is due on the selected day (T-012 B.3, T-022).
    public static func nothingDue(onToday: Bool) -> String {
        onToday ? "Nothing due today" : "Nothing due that day"
    }

    /// "Habits, Friday, October 23": the header's spoken label, with the date in full (T-022 B.9).
    public static func listHeaderSpoken(day: Day, today: Day) -> String {
        day == today ? "Habits" : "Habits, \(MonthNames.spokenDate(day))"
    }

    /// "FRI, OCT 23" after the Habits label while another day is selected; nil on today (T-022).
    public static func listHeader(day: Day, today: Day) -> String? {
        guard day != today else { return nil }
        return "\(MonthNames.weekdayName(day.weekday).prefix(3)), \(shortDate(day))".uppercased()
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
