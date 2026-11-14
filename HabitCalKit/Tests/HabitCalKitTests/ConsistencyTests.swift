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
        // The week from Sunday is Oct 25–29; today isn't done, so the due days are the 25th to the 28th.
        let pushUps = habit("Push-ups", done: [oct(25), oct(26)])
        let tally = Consistency.tally(pushUps, range: .week, today: today, weekStart: .sunday)
        #expect(tally == ConsistencyTally(done: 2, due: 4))
        #expect(tally.share == 0.5)
    }

    @Test func rangesStartAtTheFirstDayOfTheirPeriod() {
        #expect(ConsistencyRange.week.start(today: today, weekStart: .sunday) == oct(25))
        #expect(ConsistencyRange.week.start(today: today, weekStart: .monday) == oct(26))
        let sunday = Day(year: 2026, month: 11, day: 1)
        #expect(ConsistencyRange.week.start(today: sunday, weekStart: .sunday) == sunday)
        #expect(ConsistencyRange.week.start(today: sunday, weekStart: .monday) == oct(26))
        #expect(ConsistencyRange.month.start(today: today, weekStart: .sunday) == oct(1))
        #expect(ConsistencyRange.year.start(today: today, weekStart: .sunday) == Day(year: 2026, month: 1, day: 1))
    }

    @Test func scoreBoxNamesThePeriodStartAndDaysLeft() {
        let friday = Day(year: 2026, month: 11, day: 13)
        func left(_ range: ConsistencyRange, _ today: Day = friday, _ weekStart: WeekStart = .sunday) -> [String] {
            let figure = range.daysLeftFigure(today: today, weekStart: weekStart)
            return [figure.value, figure.label]
        }
        #expect(ConsistencyRange.week.startText(today: friday, weekStart: .monday) == "11/9")
        #expect(left(.week, friday, .monday) == ["2", "days left"])
        #expect(ConsistencyRange.week.startText(today: friday, weekStart: .sunday) == "11/8")
        #expect(left(.week) == ["1", "day left"])
        #expect(left(.month) == ["17", "days left"])
        #expect(ConsistencyRange.year.startText(today: friday, weekStart: .sunday) == "1/1")
        #expect(left(.year) == ["48", "days left"])
        let lastOfYear = Day(year: 2026, month: 12, day: 31)
        #expect(left(.month, lastOfYear) == ["Last", "day"])
        #expect(left(.year, lastOfYear) == ["Last", "day"])
        #expect(
            ConsistencyRange.month.end(today: Day(year: 2028, month: 2, day: 3), weekStart: .sunday)
                == Day(year: 2028, month: 2, day: 29))
        #expect(
            ConsistencyRange.week.periodSpoken(today: friday, weekStart: .monday) == "Since November 9, 2 days left")
    }

    @Test func rangesAreWeekMonthAndYearToDate() {
        let pushUps = habit("Push-ups", addedOn: Day(year: 2026, month: 9, day: 1), done: [oct(25), oct(26)])
        func tally(_ range: ConsistencyRange, _ weekStart: WeekStart = .sunday) -> ConsistencyTally {
            Consistency.tally(pushUps, range: range, today: today, weekStart: weekStart)
        }
        #expect(tally(.week, .sunday) == ConsistencyTally(done: 2, due: 4))  // Sun 25 – Wed 28
        #expect(tally(.week, .monday) == ConsistencyTally(done: 1, due: 3))  // Mon 26 – Wed 28
        #expect(tally(.month) == ConsistencyTally(done: 2, due: 28))  // Oct 1–28
        #expect(tally(.year) == ConsistencyTally(done: 2, due: 58))  // from Sep 1, when it was added
    }

    @Test func rangesStartNoEarlierThanTheHabit() {
        let run = habit("Run", days: [6, 1], addedOn: oct(9), done: [oct(9)])  // Fri, Sun; added Friday Oct 9
        // Month to date from Oct 9, not Oct 1: Oct 9, 11, 16, 18, 23, 25 (today, Thursday, isn't due).
        #expect(
            Consistency.tally(run, range: .month, today: today, weekStart: .sunday) == ConsistencyTally(done: 1, due: 6)
        )
        #expect(
            Consistency.tally(run, range: .year, today: today, weekStart: .sunday) == ConsistencyTally(done: 1, due: 6))
        // A check-off before it was added starts it there: Sun 4, then Fri 9 onward.
        let early = habit("Run", days: [6, 1], addedOn: oct(9), done: [oct(4), oct(9)])
        #expect(
            Consistency.tally(early, range: .month, today: today, weekStart: .sunday)
                == ConsistencyTally(done: 2, due: 7))
        // Added today: nothing before it counts, so nothing is due yet.
        let fresh = habit("Read", addedOn: today)
        #expect(
            Consistency.tally(fresh, range: .week, today: today, weekStart: .sunday)
                == ConsistencyTally(done: 0, due: 0))
    }

    @Test func todayCountsOnlyOnceDone() {
        let notYet = habit("Read", addedOn: today)
        #expect(
            Consistency.tally(notYet, range: .year, today: today, weekStart: .sunday)
                == ConsistencyTally(done: 0, due: 0))
        #expect(Consistency.tally(notYet, range: .year, today: today, weekStart: .sunday).share == nil)
        let done = habit("Read", addedOn: today, done: [today])
        #expect(
            Consistency.tally(done, range: .year, today: today, weekStart: .sunday) == ConsistencyTally(done: 1, due: 1)
        )
    }

    @Test func boardRanksByShareTiesKeepOrderAndNoDueDaysLast() {
        let week = (25...28).map(oct)  // the week from Sunday, before today
        let fresh = habit("Fresh", addedOn: today)  // no due days yet
        let half = habit("Half", done: Array(week.prefix(2)))
        let fullA = habit("Full A", done: week)
        let fullB = habit("Full B", done: week)
        let board = Consistency.board([fresh, half, fullA, fullB], range: .week, today: today, weekStart: .sunday)
        #expect(board.map(\.habit.name) == ["Full A", "Full B", "Half", "Fresh"])
    }

    @Test func overallPoolsAllHabits() {
        let week = (25...28).map(oct)
        let daily = habit("Daily", done: week)  // 4 of 4
        let sundays = habit("Sundays", days: [1])  // Oct 25 due, missed: 0 of 1
        let board = Consistency.board([daily, sundays], range: .week, today: today, weekStart: .sunday)
        #expect(Consistency.overall(board) == ConsistencyTally(done: 4, due: 5))
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
        #expect(ConsistencyRange.allCases.map(\.title) == ["Week", "Month", "Year"])
        #expect(
            ConsistencyRange.allCases.map { $0.caption(weekStart: .monday) }
                == ["Monday to date", "Month to date", "Year to date"])
        #expect(ConsistencyRange.week.caption(weekStart: .sunday) == "Sunday to date")
        #expect(ConsistencyRange.week.spoken(weekStart: .monday) == "Week, Monday to date")
        #expect(
            ConsistencyRange.allCases.map(\.noHabitsMessage)
                == [
                    "Start a habit\ntoday!", "Give it a month,\nsee what happens!",
                    "Imagine what you could do in a year!",
                ])
        #expect(Consistency.scoreSpoken(ConsistencyTally(done: 0, due: 0)) == "No due days yet")
    }

    @Test func rowDetailsReadEventsCompletedAndStreak() {
        #expect(Consistency.eventsText(ConsistencyTally(done: 9, due: 12)) == "12 events · 9 completed")
        #expect(Consistency.eventsText(ConsistencyTally(done: 1, due: 1)) == "1 event · 1 completed")
        #expect(Consistency.eventsText(ConsistencyTally(done: 0, due: 0)) == "0 events · 0 completed")
        #expect(Consistency.streakText(5) == "5 streak")
        #expect(
            Consistency.detailSpoken(ConsistencyTally(done: 9, due: 12), streak: 5)
                == "12 events, 9 completed, 5 streak")
    }

    @Test func motivationNeverRepeatsTheLastMessage() {
        #expect((5...10).contains(Motivation.messages.count))
        #expect(Set(Motivation.messages).count == Motivation.messages.count)
        #expect(Motivation.messages.allSatisfy { $0.hasSuffix("!") })  // upbeat, every one (customer)
        for last in Motivation.messages {
            for pick in 0..<(Motivation.messages.count - 1) {
                #expect(Motivation.next(after: last, random: { _ in pick }) != last)
            }
        }
        #expect(Motivation.next(after: nil, random: { _ in 0 }) == Motivation.messages[0])
    }

    @Test func onlyAPerfectRecordShowsOneHundredPercent() {
        #expect(Consistency.percentText(ConsistencyTally(done: 299, due: 300)) == "99%")
        #expect(Consistency.percentText(ConsistencyTally(done: 300, due: 300)) == "100%")
        #expect(Consistency.percentText(ConsistencyTally(done: 1, due: 300)) == "1%")
        #expect(Consistency.percentText(ConsistencyTally(done: 0, due: 300)) == "0%")
    }
}
