/// A month of a year, as shown in the calendar.
public struct Month: Hashable, Sendable {
    public let year: Int
    public let month: Int

    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    /// The month `day` falls in.
    public init(_ day: Day) {
        self.init(year: day.year, month: day.month)
    }

    public var next: Month {
        month == 12 ? Month(year: year + 1, month: 1) : Month(year: year, month: month + 1)
    }

    public var previous: Month {
        month == 1 ? Month(year: year - 1, month: 12) : Month(year: year, month: month - 1)
    }

    public var firstDay: Day {
        Day(year: year, month: month, day: 1)
    }

    public func contains(_ day: Day) -> Bool {
        day.year == year && day.month == month
    }

    /// "October 2026".
    public var title: String {
        "\(MonthNames.name(of: month)) \(year)"
    }
}
