import Testing

@testable import HabitCalKit

@Suite("Calendar")
struct CalendarTests {
    @Test(arguments: [WeekStart.sunday, .monday])
    func gridAlwaysHasSixWeeksStartingOnWeekStart(weekStart: WeekStart) {
        for month in (1...12).map({ Month(year: 2026, month: $0) }) {
            let days = MonthGrid.days(in: month, weekStart: weekStart)
            #expect(days.count == 42)
            #expect(days.first?.weekday == weekStart.weekday)
            #expect(zip(days, days.dropFirst()).allSatisfy { $0.adding(days: 1) == $1 })
        }
    }

    @Test func gridIncludesNeighbouringMonthDays() {
        // October 2026 starts on a Thursday.
        let sundayFirst = MonthGrid.days(in: Month(year: 2026, month: 10), weekStart: .sunday)
        #expect(sundayFirst.first == Day(year: 2026, month: 9, day: 27))
        #expect(sundayFirst[4] == Day(year: 2026, month: 10, day: 1))
        #expect(sundayFirst.last == Day(year: 2026, month: 11, day: 7))

        let mondayFirst = MonthGrid.days(in: Month(year: 2026, month: 10), weekStart: .monday)
        #expect(mondayFirst.first == Day(year: 2026, month: 9, day: 28))
    }

    @Test func nextAndPreviousMonthCrossYearBoundaries() {
        #expect(Month(year: 2026, month: 12).next == Month(year: 2027, month: 1))
        #expect(Month(year: 2027, month: 1).previous == Month(year: 2026, month: 12))
        // No limit on paging (B.10): a century back and forth lands where it started.
        var month = Month(year: 2026, month: 10)
        for _ in 0..<1200 { month = month.previous }
        #expect(month == Month(year: 1926, month: 10))
        for _ in 0..<1200 { month = month.next }
        #expect(month == Month(year: 2026, month: 10))
        #expect(Month(Day(year: 2026, month: 10, day: 29)) == Month(year: 2026, month: 10))
        #expect(Month(year: 2026, month: 10).contains(Day(year: 2026, month: 10, day: 31)))
        #expect(!Month(year: 2026, month: 10).contains(Day(year: 2026, month: 11, day: 1)))
    }

    @Test func macFirstWeekdayMapsMondayToMondayAndOthersToSunday() {
        #expect(WeekStart.fromMac(firstWeekday: 1) == .sunday)
        #expect(WeekStart.fromMac(firstWeekday: 2) == .monday)
        for other in 3...7 {
            #expect(WeekStart.fromMac(firstWeekday: other) == .sunday)
        }
    }

    @Test func spokenFullDateIncludesTheYear() {
        #expect(MonthNames.spokenFullDate(Day(year: 2026, month: 10, day: 29)) == "Thursday, October 29, 2026")
    }
}
