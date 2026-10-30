import Foundation
import Testing

@testable import HabitCalKit

/// Oct 2026: Fri 2, Sun 4, Fri 9, Sun 11, Wed 14, Fri 16, Sun 18, Wed 21.
private func oct(_ d: Int) -> Day { Day(year: 2026, month: 10, day: d) }
private let friSun: Set<Int> = [6, 1]

private func habit(days: Set<Int> = friSun, addedOn: Day = oct(1), done: [Int], schedule: [ScheduleEntry]? = nil)
    -> Habit
{
    Habit(
        id: UUID(), name: "Run", note: "", addedOn: addedOn,
        schedule: schedule ?? [ScheduleEntry(from: addedOn, days: days)], checkOffs: Set(done.map(oct)))
}

@Suite("Streaks")
struct StreakTests {
    @Test func streakCountsOnlyDueDays() {
        // Fri ✓, Sun ✓, today Wed (not due).
        let run = habit(done: [2, 4])
        #expect(Streaks.current(run, today: oct(7)) == 2)
        #expect(Streaks.best(run, today: oct(7)) == 2)
        // Fri ✓, Sun ✓, today Fri ✓.
        let three = habit(done: [2, 4, 9])
        #expect(Streaks.current(three, today: oct(9)) == 3)
        #expect(Streaks.best(three, today: oct(9)) == 3)
    }

    @Test func todayDoesNotBreakTheStreakBeforeItIsDone() {
        // Fri ✓, Sun ✓, today Fri (due, not done yet).
        let run = habit(done: [2, 4])
        #expect(Streaks.current(run, today: oct(9)) == 2)
        #expect(Streaks.best(run, today: oct(9)) == 2)
        // Once the day is over, the missed Friday breaks it.
        #expect(Streaks.current(run, today: oct(10)) == 0)
    }

    @Test func bestStreakIsTheLongestRunEver() {
        // Fri ✓, Sun ✓, Fri ✓, Sun ✗, today Fri ✓.
        let run = habit(done: [2, 4, 9, 16])
        #expect(Streaks.current(run, today: oct(16)) == 1)
        #expect(Streaks.best(run, today: oct(16)) == 3)
        // Fri ✓, Sun ✗, today Wed.
        let broken = habit(done: [2])
        #expect(Streaks.current(broken, today: oct(7)) == 0)
        #expect(Streaks.best(broken, today: oct(7)) == 1)
    }

    @Test func newHabitNotDueTodayHasNoStreak() {
        let run = habit(addedOn: oct(28), done: [])  // added Wednesday
        #expect(Streaks.current(run, today: oct(28)) == 0)
        #expect(Streaks.best(run, today: oct(28)) == 0)
    }

    @Test func streakRunsAcrossAScheduleChange() {
        // Fri/Sun until the 14th, then Wednesdays only: Fri 9 ✓, Sun 11 ✓, Wed 14 ✓, Wed 21 ✓.
        let run = habit(
            done: [9, 11, 14, 21],
            schedule: [ScheduleEntry(from: oct(1), days: friSun), ScheduleEntry(from: oct(14), days: [4])])
        #expect(Streaks.current(run, today: oct(22)) == 4)
        #expect(Streaks.best(run, today: oct(22)) == 4)
    }

    @Test func streakIgnoresDaysBeforeAddedAndCheckOffsAfterToday() {
        // Added Fri 9; a stray check-off on Sun 4 (before) and Fri 16 (after today, the clock moved back).
        let run = habit(addedOn: oct(9), done: [4, 9, 11, 16])
        #expect(Streaks.current(run, today: oct(14)) == 2)
        #expect(Streaks.best(run, today: oct(14)) == 2)
    }

    @Test func streakSpokenLabelUsesDayAndDays() {
        #expect(Streaks.spoken(current: 12, best: 30) == "Current streak 12 days, best streak 30 days")
        #expect(Streaks.spoken(current: 1, best: 1) == "Current streak 1 day, best streak 1 day")
    }
}
