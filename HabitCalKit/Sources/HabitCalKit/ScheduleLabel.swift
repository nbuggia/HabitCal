/// The schedule shown under a habit's name (T-003 §5).
public enum ScheduleLabel {
    private static let shortNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    /// Monday first, whatever the week start, so "Fri, Sun" reads as a weekend run.
    private static let mondayFirst = [2, 3, 4, 5, 6, 7, 1]

    public static func text(for days: Set<Int>) -> String {
        switch days {
        case Set(1...7): "Every day"
        case [2, 3, 4, 5, 6]: "Weekdays"
        case [1, 7]: "Weekends"
        default: mondayFirst.filter(days.contains).map { shortNames[$0 - 1] }.joined(separator: ", ")
        }
    }
}
