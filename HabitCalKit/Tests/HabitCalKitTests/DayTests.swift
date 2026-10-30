import Foundation
import Testing

@testable import HabitCalKit

@Suite("Menu bar")
struct DayTests {
    @Test func dayFromDateUsesTheGivenCalendarsTimeZone() throws {
        // 02:00 UTC on Oct 30 is still the evening of Oct 29 in New York.
        let instant = try #require(ISO8601DateFormatter().date(from: "2026-10-30T02:00:00Z"))
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))

        #expect(Day(instant, calendar: newYork) == Day(year: 2026, month: 10, day: 29))
        #expect(Day(instant, calendar: tokyo) == Day(year: 2026, month: 10, day: 30))
    }

    @Test func fixedTodaySourceAlwaysReturnsItsDay() {
        let day = Day(year: 2026, month: 10, day: 29)
        #expect(FixedTodaySource(day).today(in: .autoupdatingCurrent) == day)
    }

    @Test func dayParsesAndPrintsYearMonthDay() {
        #expect(Day(iso: "2026-10-29") == Day(year: 2026, month: 10, day: 29))
        #expect(Day(iso: "2026-02-30") == nil)
        #expect(Day(iso: "nonsense") == nil)
        #expect(Day(year: 2026, month: 3, day: 7).iso == "2026-03-07")
    }
}
