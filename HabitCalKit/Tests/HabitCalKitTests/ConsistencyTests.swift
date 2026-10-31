import Foundation
import Testing

@testable import HabitCalKit

/// Oct 2026: the 29th ("today" in these tests) is a Thursday.
private func oct(_ d: Int) -> Day { Day(year: 2026, month: 10, day: d) }
private let today = oct(29)
private let everyDay = Set(1...7)

private func habit(_ name: String, days: Set<Int> = everyDay, addedOn: Day = oct(1), done: [Day] = []) -> Habit {
    Habit(
        id: UUID(), name: name, note: "", addedOn: addedOn,
        schedule: [ScheduleEntry(from: addedOn, days: days)], checkOffs: Set(done))
}

@Suite("Consistency")
struct ConsistencyTests {
    @Test func shareCountsDueDaysCheckedOffInTheRange() {
        // Past 7 days is Oct 23–29; today isn't done, so the due days are the 23rd to the 28th.
        let pushUps = habit("Push-ups", done: [oct(23), oct(24), oct(25)])
        let tally = Consistency.tally(pushUps, range: .past7, today: today)
        #expect(tally == ConsistencyTally(done: 3, due: 6))
        #expect(tally.share == 0.5)
    }

    @Test func rangesAreRollingWindowsEndingToday() {
        let pushUps = habit("Push-ups", addedOn: Day(year: 2026, month: 9, day: 1), done: [oct(22), oct(23)])
        // Oct 22 is outside the past 7 days (Oct 23–29) but inside the past 30 (Sep 30 – Oct 29).
        #expect(Consistency.tally(pushUps, range: .past7, today: today) == ConsistencyTally(done: 1, due: 6))
        #expect(Consistency.tally(pushUps, range: .past30, today: today) == ConsistencyTally(done: 2, due: 29))
    }

    @Test func allTimeStartsAtTheEarlierOfAddedAndFirstCheckOff() {
        let run = habit("Run", days: [6, 1], addedOn: oct(9), done: [oct(9)])  // Fri, Sun; added Friday Oct 9
        // All time from Oct 9: Oct 9, 11, 16, 18, 23, 25 (today, Thursday, isn't due).
        #expect(Consistency.tally(run, range: .allTime, today: today) == ConsistencyTally(done: 1, due: 6))
        // A rolling window counts days before it was added too (T-028): add Fri 2 and Sun 4.
        #expect(Consistency.tally(run, range: .past30, today: today) == ConsistencyTally(done: 1, due: 8))
        // A check-off before it was added starts All time there: Sun 4, then Fri 9 onward.
        let early = habit("Run", days: [6, 1], addedOn: oct(9), done: [oct(4), oct(9)])
        #expect(Consistency.tally(early, range: .allTime, today: today) == ConsistencyTally(done: 2, due: 7))
    }

    @Test func rollingWindowCountsDaysBeforeAHabitWasAdded() {
        // Added today, every day: Oct 23–28 were due and missed (T-028 B.4).
        let fresh = habit("Read", addedOn: today)
        #expect(Consistency.tally(fresh, range: .past7, today: today) == ConsistencyTally(done: 0, due: 6))
    }

    @Test func todayCountsOnlyOnceDone() {
        let notYet = habit("Read", addedOn: today)
        #expect(Consistency.tally(notYet, range: .allTime, today: today) == ConsistencyTally(done: 0, due: 0))
        #expect(Consistency.tally(notYet, range: .allTime, today: today).share == nil)
        let done = habit("Read", addedOn: today, done: [today])
        #expect(Consistency.tally(done, range: .allTime, today: today) == ConsistencyTally(done: 1, due: 1))
    }

    @Test func boardRanksByShareTiesKeepOrderAndNoDueDaysLast() {
        let week = (23...28).map(oct)
        let fresh = habit("Fresh", addedOn: today)  // no due days yet
        let half = habit("Half", done: Array(week.prefix(3)))
        let fullA = habit("Full A", done: week)
        let fullB = habit("Full B", done: week)
        let board = Consistency.board([fresh, half, fullA, fullB], range: .allTime, today: today)
        #expect(board.map(\.habit.name) == ["Full A", "Full B", "Half", "Fresh"])
    }

    @Test func overallPoolsAllHabits() {
        let week = (23...28).map(oct)
        let daily = habit("Daily", done: week)  // 6 of 6
        let sundays = habit("Sundays", days: [1])  // Oct 25 due, missed: 0 of 1
        let board = Consistency.board([daily, sundays], range: .past7, today: today)
        #expect(Consistency.overall(board) == ConsistencyTally(done: 6, due: 7))
        #expect(Consistency.overall([]) == ConsistencyTally(done: 0, due: 0))
    }

    @Test func labelsReadPercentAndOrdinal() {
        #expect(Consistency.percentText(ConsistencyTally(done: 6, due: 7)) == "86%")
        #expect(Consistency.percentText(ConsistencyTally(done: 0, due: 0)) == "—")
        #expect(
            Consistency.rowSpoken(rank: 1, name: "Read", tally: ConsistencyTally(done: 13, due: 14))
                == "1st, Read, 93 percent")
        #expect(
            Consistency.rowSpoken(rank: 3, name: "Fresh", tally: ConsistencyTally(done: 0, due: 0))
                == "3rd, Fresh, no due days")
        #expect(
            Consistency.scoreSpoken(ConsistencyTally(done: 6, due: 7))
                == "86 percent of due days done across all habits")
        #expect(ConsistencyRange.allCases.map(\.title) == ["Past 7 days", "Past 30 days", "All time"])
        #expect(Consistency.scoreSpoken(ConsistencyTally(done: 0, due: 0)) == "No due days yet")
    }

    @Test func onlyAPerfectRecordShowsOneHundredPercent() {
        #expect(Consistency.percentText(ConsistencyTally(done: 299, due: 300)) == "99%")
        #expect(Consistency.percentText(ConsistencyTally(done: 300, due: 300)) == "100%")
        #expect(Consistency.percentText(ConsistencyTally(done: 1, due: 300)) == "1%")
        #expect(Consistency.percentText(ConsistencyTally(done: 0, due: 300)) == "0%")
    }
}
