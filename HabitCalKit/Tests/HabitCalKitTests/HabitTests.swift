import Foundation
import Testing

@testable import HabitCalKit

/// Oct 2026: the 1st is a Thursday; the 29th ("today" in these tests) is a Thursday.
private func oct(_ d: Int) -> Day { Day(year: 2026, month: 10, day: d) }
private let today = oct(29)
private let fri = 6
private let sun = 1

@Suite("Habits")
struct HabitTests {
    private func runHabit(addedOn: Day = oct(1)) -> (Habits, UUID) {
        var habits = Habits()
        let id = habits.add(HabitDraft(name: "Run", note: "", days: [fri, sun]), today: addedOn)
        return (habits, id)
    }

    @Test func habitIsDueOnlyOnScheduledWeekdaysFromTheDayItWasAdded() throws {
        let (habits, id) = runHabit(addedOn: oct(9))  // a Friday
        let habit = try #require(habits[id])
        #expect(!habit.isDue(on: oct(2)))  // a Friday before it was added
        #expect(habit.isDue(on: oct(9)))  // Friday
        #expect(habit.isDue(on: oct(11)))  // Sunday
        #expect(!habit.isDue(on: oct(12)))  // Monday
    }

    @Test func scheduleChangeAppliesFromTodayAndKeepsPastDays() throws {
        var (habits, id) = runHabit()
        habits.update(id, with: HabitDraft(name: "Run", note: "", days: [2, 4, 6]), today: today)  // Mon, Wed, Fri
        let habit = try #require(habits[id])
        #expect(habit.isDue(on: oct(25)))  // a past Sunday keeps the old schedule
        #expect(habit.isDue(on: Day(year: 2026, month: 11, day: 2)))  // Monday, new schedule
        #expect(!habit.isDue(on: Day(year: 2026, month: 11, day: 1)))  // Sunday, new schedule
    }

    @Test func secondScheduleChangeTheSameDayReplacesTheFirst() throws {
        var (habits, id) = runHabit()
        habits.update(id, with: HabitDraft(name: "Run", note: "", days: [2]), today: today)
        habits.update(id, with: HabitDraft(name: "Run", note: "", days: [3]), today: today)
        let habit = try #require(habits[id])
        #expect(habit.schedule.count == 2)
        #expect(habit.days(on: today) == [3])
        #expect(habit.days(on: oct(28)) == [fri, sun])
    }

    @Test func editingAHabitAddedTodayChangesItsOnlySchedule() throws {
        var (habits, id) = runHabit(addedOn: today)
        habits.update(id, with: HabitDraft(name: "Run", note: "", days: [5]), today: today)
        let habit = try #require(habits[id])
        #expect(habit.schedule.count == 1)
        #expect(habit.isDue(on: today))
    }

    @Test func togglingOnlyWorksOnDueDaysUpToToday() throws {
        var (habits, id) = runHabit()
        let checked = habits.toggle(id, on: oct(25), today: today)  // past Sunday
        #expect(checked)
        #expect(try #require(habits[id]).isDone(on: oct(25)))
        let unchecked = habits.toggle(id, on: oct(25), today: today)  // and back
        #expect(unchecked)
        #expect(try !#require(habits[id]).isDone(on: oct(25)))
        let notDue = habits.toggle(id, on: oct(26), today: today)  // Monday: not due
        #expect(!notDue)
        let future = habits.toggle(id, on: oct(30), today: today)  // Friday: future
        #expect(!future)
    }

    @Test func droppingTodayFromTheScheduleRemovesTodaysCheckOff() throws {
        var habits = Habits()
        let id = habits.add(HabitDraft(name: "Push-ups", note: "", days: Set(1...7)), today: oct(1))
        habits.toggle(id, on: today, today: today)
        habits.update(id, with: HabitDraft(name: "Push-ups", note: "", days: [fri]), today: today)
        let habit = try #require(habits[id])
        #expect(!habit.isDone(on: today))
    }

    @Test func stripShowsDoneMissedNotScheduledAndFutureForTheMonth() throws {
        var (habits, id) = runHabit()
        habits.toggle(id, on: oct(2), today: today)  // Fri done
        let strip = try #require(habits[id]).strip(for: Month(year: 2026, month: 10), today: today)
        #expect(strip.count == 31)
        #expect(strip[1] == .done)  // Oct 2, Fri
        #expect(strip[3] == .missed)  // Oct 4, Sun
        #expect(strip[0] == .notScheduled)  // Oct 1, Thu
        #expect(strip[28] == .notScheduled)  // Oct 29, today, Thu
        #expect(strip[29] == .future)  // Oct 30, Fri
        #expect(strip[30] == .futureNotScheduled)  // Oct 31, Sat

        let november = try #require(habits[id]).strip(for: Month(year: 2026, month: 11), today: today)
        #expect(november[30] == .blank)  // November has 30 days
    }

    @Test func checkOffsAfterTodayAreShownAsFuture() throws {
        // The clock moved backward past a check-off (E.7).
        var (habits, id) = runHabit()
        habits.toggle(id, on: oct(30), today: oct(30))
        let habit = try #require(habits[id])
        #expect(habit.strip(for: Month(year: 2026, month: 10), today: today)[29] == .future)
    }

    @Test func draftNeedsANameAndADay() {
        #expect(HabitDraft(name: "Run", note: "", days: [1]).isValid)
        #expect(!HabitDraft(name: "   ", note: "", days: [1]).isValid)
        #expect(!HabitDraft(name: "Run", note: "", days: []).isValid)
    }

    @Test func draftTrimsNameAndNote() {
        let draft = HabitDraft(name: "  Run  ", note: "\n5k loop \n", days: [1]).trimmed
        #expect(draft.name == "Run")
        #expect(draft.note == "5k loop")
    }

    @Test func draftClampsNameAndNoteLength() {
        let draft = HabitDraft(
            name: String(repeating: "a", count: 50), note: String(repeating: "b", count: 300), days: [1]
        )
        .clamped
        #expect(draft.name.count == HabitDraft.maxNameLength)
        #expect(draft.note.count == HabitDraft.maxNoteLength)
    }

    @Test func scheduleLabelNamesCommonSchedulesAndListsOthersMondayFirst() {
        #expect(ScheduleLabel.text(for: Set(1...7)) == "Every day")
        #expect(ScheduleLabel.text(for: [2, 3, 4, 5, 6]) == "Weekdays")
        #expect(ScheduleLabel.text(for: [1, 7]) == "Weekends")
        #expect(ScheduleLabel.text(for: [fri, sun]) == "Fri, Sun")
        #expect(ScheduleLabel.text(for: [2, 4, 6]) == "Mon, Wed, Fri")
    }

    @Test func newHabitsGoToTheBottomAndNamesMayRepeat() {
        var habits = Habits()
        let a = habits.add(HabitDraft(name: "Run", note: "", days: [1]), today: today)
        let b = habits.add(HabitDraft(name: "Run", note: "", days: [1]), today: today)
        #expect(habits.all.map(\.id) == [a, b])
    }

    @Test func deletingAHabitRemovesItAndItsHistory() {
        var (habits, id) = runHabit()
        habits.toggle(id, on: oct(25), today: today)
        habits.delete(id)
        #expect(habits[id] == nil)
        #expect(habits.all.isEmpty)
    }

    @Test func addedOnGovernsWhenTheScheduleStartsLater() {
        // After the clock moves backward, an edit can start the schedule before addedOn (E.7). Legal.
        let habit = Habit(
            id: UUID(), name: "Run", note: "", addedOn: oct(5),
            schedule: [ScheduleEntry(from: oct(9), days: [fri])], checkOffs: [])
        #expect(!habit.isDue(on: oct(2)))  // before addedOn
        #expect(habit.days(on: oct(6)) == [fri])  // before the first entry: the first entry applies
        #expect(habit.isDue(on: oct(9)))
    }

    @Test func labelsDescribeEachDayAndButton() {
        #expect(HabitLabels.stripTooltip(oct(5), .done) == "Oct 5 · done")
        #expect(HabitLabels.stripTooltip(oct(5), .missed) == "Oct 5 · missed")
        #expect(HabitLabels.stripTooltip(oct(4), .notScheduled) == "Oct 4 · not scheduled")
        #expect(HabitLabels.stripTooltip(oct(30), .future) == "Oct 30")
        #expect(HabitLabels.stripTooltip(oct(31), .futureNotScheduled) == "Oct 31 · not scheduled")
        #expect(HabitLabels.stripSpoken(oct(5), .done) == "October 5, done")
        #expect(
            HabitLabels.doneButtonSpoken(name: "Push-ups", dueToday: true, doneToday: true) == "Push-ups, done today")
        #expect(
            HabitLabels.doneButtonSpoken(name: "Push-ups", dueToday: true, doneToday: false)
                == "Push-ups, not done today")
        #expect(
            HabitLabels.doneButtonSpoken(name: "Push-ups", dueToday: false, doneToday: false)
                == "Push-ups, not scheduled today")
        #expect(HabitLabels.doneButtonTooltip(dueToday: true, doneToday: false) == "Mark done today")
        #expect(HabitLabels.doneButtonTooltip(dueToday: true, doneToday: true) == "Done today — click to undo")
        #expect(HabitLabels.doneButtonTooltip(dueToday: false, doneToday: false) == "Not scheduled today")
        #expect(HabitLabels.editSpoken(name: "Push-ups") == "Edit Push-ups")
    }

    @Test func dueAndNotDueSplitTheListInOrderAdded() {
        var habits = Habits()
        habits.add(HabitDraft(name: "Push-ups", note: "", days: Set(1...7)), today: oct(1))
        habits.add(HabitDraft(name: "Run", note: "", days: [fri, sun]), today: oct(1))
        habits.add(HabitDraft(name: "Read", note: "", days: [5]), today: oct(1))  // Thursday
        habits.add(HabitDraft(name: "Swim", note: "", days: [sun]), today: oct(1))
        #expect(habits.dueOn(today).map(\.name) == ["Push-ups", "Read"])
        #expect(habits.notDueOn(today).map(\.name) == ["Run", "Swim"])
        #expect(habits.dueOn(oct(25)).map(\.name) == ["Push-ups", "Run", "Swim"])  // a Sunday
        #expect(habits.notDueOn(oct(25)).map(\.name) == ["Read"])
    }

    @Test func notDueRowLabelsCountHabits() {
        #expect(HabitLabels.notDueRowTitle(count: 1) == "1 not due today")
        #expect(HabitLabels.notDueRowTitle(count: 3) == "3 not due today")
        #expect(HabitLabels.notDueRowSpoken(count: 1) == "1 habit not due today")
        #expect(HabitLabels.notDueRowSpoken(count: 3) == "3 habits not due today")
    }
}
