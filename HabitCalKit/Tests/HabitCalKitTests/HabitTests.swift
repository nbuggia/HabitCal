import Foundation
import Testing

@testable import HabitCalKit

/// A fixed moment for changes whose time doesn't matter to the test.
private let t0 = Date(timeIntervalSince1970: 1_793_000_000)

/// Oct 2026: the 1st is a Thursday; the 29th ("today" in these tests) is a Thursday.
private func oct(_ d: Int) -> Day { Day(year: 2026, month: 10, day: d) }
private let today = oct(29)
private let fri = 6
private let sun = 1

@Suite("Habits")
struct HabitTests {
    private func runHabit(addedOn: Day = oct(1)) -> (Habits, UUID) {
        var habits = Habits()
        let id = habits.add(HabitDraft(name: "Run", note: "", days: [fri, sun]), today: addedOn, now: t0)
        return (habits, id)
    }

    @Test func habitIsDueOnEveryScheduledWeekdayBeforeAndAfterItWasAdded() throws {
        let (habits, id) = runHabit(addedOn: oct(9))  // a Friday
        let habit = try #require(habits[id])
        #expect(habit.isDue(on: oct(2)))  // a Friday before it was added (T-028)
        #expect(!habit.isDue(on: oct(5)))  // a Monday before it was added
        #expect(habit.isDue(on: oct(9)))  // Friday
        #expect(habit.isDue(on: oct(11)))  // Sunday
        #expect(!habit.isDue(on: oct(12)))  // Monday
    }

    @Test func scheduleChangeAppliesFromTodayAndKeepsPastDays() throws {
        var (habits, id) = runHabit()
        // Mon, Wed, Fri
        habits.setDetails(id, HabitDraft(name: "Run", note: "", days: [2, 4, 6]), today: today, now: t0)
        let habit = try #require(habits[id])
        #expect(habit.isDue(on: oct(25)))  // a past Sunday keeps the old schedule
        #expect(habit.isDue(on: Day(year: 2026, month: 11, day: 2)))  // Monday, new schedule
        #expect(!habit.isDue(on: Day(year: 2026, month: 11, day: 1)))  // Sunday, new schedule
    }

    @Test func secondScheduleChangeTheSameDayReplacesTheFirst() throws {
        var (habits, id) = runHabit()
        habits.setDetails(id, HabitDraft(name: "Run", note: "", days: [2]), today: today, now: t0)
        habits.setDetails(id, HabitDraft(name: "Run", note: "", days: [3]), today: today, now: t0)
        let habit = try #require(habits[id])
        #expect(habit.schedule.count == 2)
        #expect(habit.days(on: today) == [3])
        #expect(habit.days(on: oct(28)) == [fri, sun])
    }

    @Test func editingAHabitAddedTodayChangesItFromTodayOn() throws {
        var (habits, id) = runHabit(addedOn: today)
        habits.setDetails(id, HabitDraft(name: "Run", note: "", days: [5]), today: today, now: t0)
        let habit = try #require(habits[id])
        // The old days stay pinned to the past, since past days are due too (T-028).
        #expect(
            habit.schedule == [ScheduleEntry(from: oct(28), days: [fri, sun]), ScheduleEntry(from: today, days: [5])])
        #expect(habit.isDue(on: today))
    }

    @Test func pastDaysBeforeAddedCanBeCheckedOff() throws {
        var (habits, id) = runHabit(addedOn: today)
        let checked = habits.toggle(id, on: oct(25), today: today, now: t0)  // a Sunday before it was added (T-028)
        #expect(checked)
        #expect(try #require(habits[id]).isDone(on: oct(25)))
    }

    @Test func togglingOnlyWorksOnDueDaysUpToToday() throws {
        var (habits, id) = runHabit()
        let checked = habits.toggle(id, on: oct(25), today: today, now: t0)  // past Sunday
        #expect(checked)
        #expect(try #require(habits[id]).isDone(on: oct(25)))
        let unchecked = habits.toggle(id, on: oct(25), today: today, now: t0)  // and back
        #expect(unchecked)
        #expect(try !#require(habits[id]).isDone(on: oct(25)))
        let notDue = habits.toggle(id, on: oct(26), today: today, now: t0)  // Monday: not due
        #expect(!notDue)
        let future = habits.toggle(id, on: oct(30), today: today, now: t0)  // Friday: future
        #expect(!future)
    }

    @Test func droppingTodayFromTheScheduleRemovesTodaysCheckOff() throws {
        var habits = Habits()
        let id = habits.add(HabitDraft(name: "Push-ups", note: "", days: Set(1...7)), today: oct(1), now: t0)
        habits.toggle(id, on: today, today: today, now: t0)
        habits.setDetails(id, HabitDraft(name: "Push-ups", note: "", days: [fri]), today: today, now: t0)
        let habit = try #require(habits[id])
        #expect(!habit.isDone(on: today))
    }

    @Test func scheduleEditOnTheDayAddedKeepsPastDaysOnTheOldSchedule() throws {
        var (habits, id) = runHabit(addedOn: today)  // Fri, Sun
        habits.toggle(id, on: oct(25), today: today, now: t0)  // Sun, before it was added
        // Mondays from today
        habits.setDetails(id, HabitDraft(name: "Run", note: "", days: [2]), today: today, now: t0)
        let habit = try #require(habits[id])
        #expect(habit.isDue(on: oct(25)))  // a past Sunday keeps the old schedule
        #expect(habit.isDone(on: oct(25)))
        #expect(!habit.isDue(on: oct(26)))  // a past Monday wasn't on the old schedule
        #expect(habit.isDue(on: Day(year: 2026, month: 11, day: 2)))  // Monday, new schedule
        #expect(Streaks.current(habit, today: today) == 1)
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
        let a = habits.add(HabitDraft(name: "Run", note: "", days: [1]), today: today, now: t0)
        let b = habits.add(HabitDraft(name: "Run", note: "", days: [1]), today: today, now: t0)
        #expect(habits.all.map(\.id) == [a, b])
    }

    @Test func deletingAHabitRemovesItAndItsHistory() {
        var (habits, id) = runHabit()
        habits.toggle(id, on: oct(25), today: today, now: t0)
        habits.delete(id, now: t0)
        #expect(habits[id] == nil)
        #expect(habits.all.isEmpty)
        #expect(habits.records.count == 1)  // kept as a record, so the delete reaches other Macs (T-039)
    }

    @Test func beforeTheFirstScheduleEntryTheFirstEntryApplies() {
        // After the clock moves backward, an edit can start the schedule after addedOn (E.7). Legal.
        let habit = Habit(
            id: UUID(), name: "Run", note: "", addedOn: oct(5),
            schedule: [ScheduleEntry(from: oct(9), days: [fri])], checkOffs: [])
        #expect(habit.isDue(on: oct(2)))  // before addedOn: due anyway (T-028)
        #expect(habit.days(on: oct(6)) == [fri])  // before the first entry: the first entry applies
        #expect(habit.isDue(on: oct(9)))
    }

    @Test func labelsDescribeEachDayAndButton() {
        #expect(
            HabitLabels.doneButtonSpoken(name: "Push-ups", doneToday: true) == "Push-ups, done today")
        #expect(
            HabitLabels.doneButtonSpoken(name: "Push-ups", doneToday: false)
                == "Push-ups, not done today")
        #expect(HabitLabels.doneButtonTooltip(doneToday: false) == "Mark done today")
        #expect(HabitLabels.doneButtonTooltip(doneToday: true) == "Done today — click to undo")
        #expect(HabitLabels.editSpoken(name: "Push-ups") == "Edit Push-ups")
    }

    @Test func listShowsOnlyHabitsDueThatDayInOrderAdded() {
        var habits = Habits()
        habits.add(HabitDraft(name: "Push-ups", note: "", days: Set(1...7)), today: oct(1), now: t0)
        habits.add(HabitDraft(name: "Run", note: "", days: [fri, sun]), today: oct(1), now: t0)
        habits.add(HabitDraft(name: "Read", note: "", days: [5]), today: oct(1), now: t0)  // Thursday
        habits.add(HabitDraft(name: "Swim", note: "", days: [sun]), today: oct(1), now: t0)
        #expect(habits.dueOn(today).map(\.name) == ["Push-ups", "Read"])
        #expect(habits.dueOn(oct(25)).map(\.name) == ["Push-ups", "Run", "Swim"])  // a Sunday
    }
}
