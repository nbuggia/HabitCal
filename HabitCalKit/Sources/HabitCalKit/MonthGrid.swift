/// The days the calendar shows for a month.
public enum MonthGrid {
    /// Always six weeks, so the popover keeps its height from month to month.
    public static let dayCount = 42

    /// Six weeks of days starting on the `weekStart` day on or before the 1st, including the
    /// neighboring months' days that fill the first and last weeks.
    public static func days(in month: Month, weekStart: WeekStart) -> [Day] {
        let first = month.firstDay
        let lead = (first.weekday - weekStart.weekday + 7) % 7
        let start = first.adding(days: -lead)
        return (0..<dayCount).map { start.adding(days: $0) }
    }
}
