import Foundation
import Testing

@testable import HabitCalKit

/// Oct 2026: the 29th ("today") is a Thursday.
private func oct(_ d: Int) -> Day { Day(year: 2026, month: 10, day: d) }
private let today = oct(29)
private let t0 = Date(timeIntervalSince1970: 1_793_000_000)
private let mon = 2
private let wed = 4
private let fri = 6

private func habit(days: Set<Int>, addedOn: Day = Day(year: 2026, month: 1, day: 1)) -> (Habits, UUID) {
    var habits = Habits()
    let id = habits.add(HabitDraft(name: "Run", note: "", days: days), today: addedOn, now: t0)
    return (habits, id)
}

@Suite("Strip")
struct StripTests {
    @Test func dueStripShowsLast30DueDaysOldestFirst() throws {
        let (habits, id) = habit(days: [mon, wed, fri])
        let strip = try #require(habits[id]).dueStrip(endingAt: oct(28), today: today)  // a Wednesday
        #expect(strip.count == 30)
        let days = strip.compactMap { $0?.day }
        #expect(days.count == 30)
        #expect(days == days.sorted())  // oldest on the left
        #expect(days.last == oct(28))
        #expect(days.allSatisfy { [mon, wed, fri].contains($0.weekday) })  // only due days
        #expect(days.first == Day(year: 2026, month: 8, day: 21))  // 30 M/W/F back: Friday, Aug 21
    }

    @Test func dueStripEndsAtTheShownDayMarked() throws {
        var (habits, id) = habit(days: Set(1...7))
        habits.toggle(id, on: oct(20), today: today, now: t0)
        let habit = try #require(habits[id])
        let todayStrip = habit.dueStrip(endingAt: today, today: today)
        #expect(todayStrip.last??.day == today && todayStrip.last??.isShown == true)
        #expect(todayStrip.compactMap { $0 }.filter(\.isShown).count == 1)
        let selected = habit.dueStrip(endingAt: oct(20), today: today)
        #expect(selected.last??.day == oct(20))
        #expect(selected.last??.state == .done)
        #expect(selected.last??.isShown == true)
        #expect(!selected.contains { $0?.day == today })  // today isn't marked, or shown, past the end
    }

    @Test func dueStripShowsDueDaysAfterTodayAsFuture() throws {
        let (habits, id) = habit(days: Set(1...7))
        let strip = try #require(habits[id]).dueStrip(endingAt: Day(year: 2026, month: 11, day: 2), today: today)
        let future = strip.compactMap { $0 }.filter { $0.day > today }
        #expect(future.count == 4)  // Oct 30, 31, Nov 1, 2
        #expect(future.allSatisfy { $0.state == .future })
        #expect(strip.compactMap { $0 }.first { $0.day == today }?.state == .missed)
    }

    @Test func dueStripShowsDaysBeforeAddedFaintUnlessDone() throws {
        var (habits, id) = habit(days: Set(1...7), addedOn: oct(20))
        habits.toggle(id, on: oct(10), today: today, now: t0)  // checked off before it was added (T-028)
        let strip = try #require(habits[id]).dueStrip(endingAt: today, today: today)
        let squares = strip.compactMap { $0 }
        #expect(squares.first { $0.day == oct(9) }?.state == .beforeAdded)
        #expect(squares.first { $0.day == oct(10) }?.state == .done)
        #expect(squares.first { $0.day == oct(21) }?.state == .missed)
    }

    @Test func dueStripKeepsPastDaysOnTheScheduleThenInForce() throws {
        var (habits, id) = habit(days: [fri])
        // Mondays from the 19th
        habits.setDetails(id, HabitDraft(name: "Run", note: "", days: [mon]), today: oct(19), now: t0)
        let days = try #require(habits[id]).dueStrip(endingAt: oct(26), today: today).compactMap { $0?.day }
        #expect(days.suffix(3) == [oct(16), oct(19), oct(26)])  // a Friday, then Mondays
    }

    @Test func dueStripIncludesACheckOffOnAnUnscheduledDay() throws {
        // A day another Mac's schedule left out stays due once checked off (T-039 B.21).
        let id = UUID()
        let habit = Habit(
            id: id, name: "Run", note: "", addedOn: oct(1), schedule: [ScheduleEntry(from: oct(1), days: [fri])],
            checkOffs: [oct(21)])  // a Wednesday
        let days = habit.dueStrip(endingAt: oct(23), today: today).compactMap { $0?.day }
        #expect(days.suffix(3) == [oct(16), oct(21), oct(23)])
    }

    @Test func dueStripLeavesBlankSlotsWhenFewerThan30DueDaysExist() throws {
        // A merged habit whose earliest schedule has no days: due days start on the 16th (T-039 B.8a).
        let habit = Habit(
            id: UUID(), name: "Run", note: "", addedOn: oct(1),
            schedule: [ScheduleEntry(from: oct(1), days: []), ScheduleEntry(from: oct(16), days: [fri])],
            checkOffs: [])
        let strip = habit.dueStrip(endingAt: oct(23), today: today)
        #expect(strip.count == 30)
        #expect(strip.compactMap { $0?.day } == [oct(16), oct(23)])
        #expect(strip.prefix(28).allSatisfy { $0 == nil })  // blank slots on the left
    }

    @Test func stripTooltipsNameTheDayAndState() {
        func square(_ day: Day, _ state: DueSquare.State) -> DueSquare {
            DueSquare(day: day, state: state, isShown: false)
        }
        #expect(HabitLabels.stripTooltip(square(oct(5), .done)) == "Oct 5 · done")
        #expect(HabitLabels.stripTooltip(square(oct(5), .missed)) == "Oct 5 · missed")
        #expect(HabitLabels.stripTooltip(square(oct(5), .beforeAdded)) == "Oct 5 · before added")
        #expect(HabitLabels.stripTooltip(square(oct(30), .future)) == "Oct 30")
    }
}
