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

    public static func < (lhs: Day, rhs: Day) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    private var isValid: Bool {
        guard (1...12).contains(month), day >= 1 else { return false }
        var parts = DateComponents(year: year, month: month)
        parts.day = 1
        let calendar = Calendar(identifier: .gregorian)
        guard let first = calendar.date(from: parts),
            let days = calendar.range(of: .day, in: .month, for: first)
        else { return false }
        return days.contains(day)
    }
}
