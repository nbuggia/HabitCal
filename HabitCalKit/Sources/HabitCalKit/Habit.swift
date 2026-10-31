import Foundation

/// A schedule that takes effect on `from`: the weekdays (1 = Sunday … 7 = Saturday) the habit repeats on.
public struct ScheduleEntry: Hashable, Sendable {
    public let from: Day
    public let days: Set<Int>

    public init(from: Day, days: Set<Int>) {
        self.from = from
        self.days = days
    }
}

/// Something the user does on certain weekdays, tracked as done or not done each day it's due.
public struct Habit: Identifiable, Hashable, Sendable {
    public let id: UUID
    public internal(set) var name: String
    public internal(set) var note: String
    /// The day the habit was added. It starts the leaderboard's All time range, but a habit is due on
    /// its scheduled days before it too (T-028). The schedule's first entry normally starts here, but
    /// after the clock moves backward it can start later; that's legal (T-003 E.7).
    public let addedOn: Day
    /// Sorted by `from`. A change applies from its day onward, so past days keep the schedule that
    /// was in force then (T-003 B.2).
    public internal(set) var schedule: [ScheduleEntry]
    public internal(set) var checkOffs: Set<Day>

    public init(id: UUID, name: String, note: String, addedOn: Day, schedule: [ScheduleEntry], checkOffs: Set<Day>) {
        self.id = id
        self.name = name
        self.note = note
        self.addedOn = addedOn
        self.schedule = schedule.sorted { $0.from < $1.from }
        self.checkOffs = checkOffs
    }

    /// The weekdays in force on `day`: the latest entry starting on or before `day`, or the first
    /// entry if none starts that early. There's no start date: a habit is due on its scheduled days
    /// before it was added too (T-028).
    public func days(on day: Day) -> Set<Int> {
        guard let first = schedule.first else { return [] }
        return schedule.last(where: { $0.from <= day })?.days ?? first.days
    }

    /// The earliest day a streak could start: the first check-off, or today if there is none. Every
    /// due day before it is missed, so walks over a habit's history begin here (T-028).
    public func trackedFrom(today: Day) -> Day {
        min(checkOffs.min() ?? today, today)
    }

    /// The days currently in force, as the form shows them.
    public func days(today: Day) -> Set<Int> {
        schedule.last(where: { $0.from <= today })?.days ?? schedule.first?.days ?? []
    }

    public func isDue(on day: Day) -> Bool {
        days(on: day).contains(day.weekday)
    }

    public func isDone(on day: Day) -> Bool {
        checkOffs.contains(day)
    }

    /// The displayed month's 31 strip squares (T-003 §5). A check-off after today shows as future,
    /// so moving the clock backward hides it until that day comes again (E.7).
    public func strip(for month: Month, today: Day) -> [StripDay] {
        (1...31).map { number in
            let day = Day(year: month.year, month: month.month, day: number)
            guard let valid = Day(iso: day.iso) else { return .blank }
            let due = isDue(on: valid)
            if valid > today { return due ? .future : .futureNotScheduled }
            if !due { return .notScheduled }
            return isDone(on: valid) ? .done : .missed
        }
    }
}

/// One square in a habit's strip.
public enum StripDay: Sendable, Equatable {
    case done
    case missed
    case notScheduled
    case future
    case futureNotScheduled
    /// Past the end of a month shorter than 31 days.
    case blank
}
