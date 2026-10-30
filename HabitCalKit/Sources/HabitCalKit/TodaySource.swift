import Foundation

/// The only source of "today" (FM-007). Named to stay clear of the standard library's `Clock`.
public protocol TodaySource: Sendable {
    func today(in calendar: Calendar) -> Day
}

/// Today according to the Mac's clock.
public struct SystemTodaySource: TodaySource {
    public init() {}

    public func today(in calendar: Calendar) -> Day {
        Day(Date.now, calendar: calendar)
    }
}

/// A fixed day, for tests and the Debug `-HabitCalToday` launch option.
public struct FixedTodaySource: TodaySource {
    public let day: Day

    public init(_ day: Day) {
        self.day = day
    }

    public func today(in calendar: Calendar) -> Day {
        day
    }
}
