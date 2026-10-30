import Foundation

/// A calendar date on the user's local calendar, with no time of day and no time zone.
///
/// Habits are tracked by date, not by instant, so a check-off made on October 5 stays on
/// October 5 when the Mac's time zone changes (FM-002). Convert from `Date` only at the app's
/// edge, with `init(_:calendar:)`.
public struct Day: Hashable, Comparable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// The date `date` falls on in `calendar`'s time zone.
    public init(_ date: Date, calendar: Calendar) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year!, month: parts.month!, day: parts.day!)
    }

    /// Parses "YYYY-MM-DD", rejecting dates that don't exist.
    public init?(iso: String) {
        let parts = iso.split(separator: "-")
        guard parts.count == 3, let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]),
            parts[0].count == 4, parts[1].count == 2, parts[2].count == 2
        else { return nil }
        let candidate = Day(year: y, month: m, day: d)
        guard candidate.isValid else { return nil }
        self = candidate
    }

    /// "YYYY-MM-DD".
    public var iso: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// The day `count` days later (or earlier, if negative).
    public func adding(days count: Int) -> Day {
        Day(Self.gregorian.date(byAdding: .day, value: count, to: noonUTC)!, calendar: Self.gregorian)
    }

    /// 1 = Sunday … 7 = Saturday.
    public var weekday: Int {
        Self.gregorian.component(.weekday, from: noonUTC)
    }

    public static func < (lhs: Day, rhs: Day) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    /// Weekday math happens in UTC on a fixed Gregorian calendar, so it never depends on the Mac's
    /// time zone or calendar settings.
    static let gregorian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    var noonUTC: Date {
        Self.gregorian.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private var isValid: Bool {
        guard (1...12).contains(month), day >= 1 else { return false }
        guard let first = Self.gregorian.date(from: DateComponents(year: year, month: month, day: 1)),
            let days = Self.gregorian.range(of: .day, in: .month, for: first)
        else { return false }
        return days.contains(day)
    }
}
