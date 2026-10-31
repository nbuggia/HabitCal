import Testing

@testable import HabitCalKit

/// T-022: labels for the habit list when a day other than today is selected.
/// Oct 2026: the 29th ("today" in these tests) is a Thursday; the 23rd is a Friday.
private func oct(_ d: Int) -> Day { Day(year: 2026, month: 10, day: d) }
private let today = oct(29)

@Suite("Day selection")
struct DaySelectionTests {
    @Test func doneButtonLabelsNameTheSelectedDay() {
        // Today reads as before.
        #expect(
            HabitLabels.doneButtonSpoken(name: "Push-ups", day: today, today: today, due: true, done: true)
                == "Push-ups, done today")
        #expect(HabitLabels.doneButtonTooltip(day: today, today: today, due: true, done: false) == "Mark done today")
        // A past day names the day.
        #expect(
            HabitLabels.doneButtonSpoken(name: "Push-ups", day: oct(23), today: today, due: true, done: true)
                == "Push-ups, done on October 23")
        #expect(
            HabitLabels.doneButtonSpoken(name: "Push-ups", day: oct(23), today: today, due: true, done: false)
                == "Push-ups, not done on October 23")
        #expect(
            HabitLabels.doneButtonSpoken(name: "Run", day: oct(22), today: today, due: false, done: false)
                == "Run, not scheduled on October 22")
        #expect(
            HabitLabels.doneButtonTooltip(day: oct(23), today: today, due: true, done: false) == "Mark done for Oct 23")
        #expect(
            HabitLabels.doneButtonTooltip(day: oct(23), today: today, due: true, done: true)
                == "Done Oct 23 — click to undo")
        // A future day can't be checked off.
        #expect(
            HabitLabels.doneButtonTooltip(day: oct(30), today: today, due: true, done: false)
                == "Can't check off a future day")
        #expect(
            HabitLabels.doneButtonSpoken(name: "Push-ups", day: oct(30), today: today, due: true, done: false)
                == "Push-ups, October 30, can't check off a future day")
    }

    @Test func aFutureDayThatIsNotDueSaysNotScheduled() {
        #expect(
            HabitLabels.doneButtonSpoken(name: "Run", day: oct(30), today: today, due: false, done: false)
                == "Run, not scheduled on October 30")
        #expect(
            HabitLabels.doneButtonTooltip(day: oct(30), today: today, due: false, done: false) == "Not scheduled Oct 30"
        )
    }

    @Test func listLabelsFollowTheSelectedDay() {
        #expect(HabitLabels.listHeaderSpoken(day: oct(23), today: today) == "Habits, Friday, October 23")
        #expect(HabitLabels.listHeaderSpoken(day: today, today: today) == "Habits")
        #expect(HabitLabels.listHeader(day: today, today: today) == nil)
        #expect(HabitLabels.listHeader(day: oct(23), today: today) == "FRI, OCT 23")
        #expect(HabitLabels.notDueRowTitle(count: 2, onToday: false) == "2 not due that day")
        #expect(HabitLabels.notDueRowSpoken(count: 1, onToday: false) == "1 habit not due that day")
        #expect(HabitLabels.nothingDue(onToday: true) == "Nothing due today")
        #expect(HabitLabels.nothingDue(onToday: false) == "Nothing due that day")
    }

    @Test func spokenCalendarDayMarksTheSelection() {
        #expect(
            MonthNames.spokenCalendarDay(oct(23), isToday: false, isSelected: true)
                == "Friday, October 23, 2026, selected")
        #expect(
            MonthNames.spokenCalendarDay(today, isToday: true, isSelected: false) == "Thursday, October 29, 2026, today"
        )
    }
}
