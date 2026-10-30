import Testing

@testable import HabitCalKit

@Suite("Menu bar")
struct MonthNamesTests {
    @Test func dayKnowsItsWeekday() {
        // 1 = Sunday … 7 = Saturday, as in Foundation's Gregorian calendar.
        #expect(Day(year: 2026, month: 10, day: 29).weekday == 5)
        #expect(Day(year: 2026, month: 11, day: 1).weekday == 1)
    }

    @Test func spokenDateReadsWeekdayMonthAndDay() {
        #expect(MonthNames.spokenDate(Day(year: 2026, month: 10, day: 29)) == "Thursday, October 29")
    }

    @Test func iconMonthIsThreeCapitalLetters() {
        #expect(MonthNames.abbreviation(of: 10) == "OCT")
        #expect(MonthNames.abbreviation(of: 5) == "MAY")
        #expect((1...12).allSatisfy { MonthNames.abbreviation(of: $0).count == 3 })
    }
}
