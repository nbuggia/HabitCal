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

/// A habit's name, note, and schedule history. They change together and sync as one unit: the later
/// edit wins for all three (T-039, customer 2026-11-01).
public struct HabitDetails: Hashable, Sendable {
    public let name: String
    public let note: String
    /// Sorted by `from`. A change applies from its day onward, so past days keep the schedule that
    /// was in force then (T-003 B.2). An entry before today can have no days: two merged copies keep
    /// only the days both had (T-039 B.8a).
    public let schedule: [ScheduleEntry]
    /// When this version was made, on its Mac. Nil for data saved before sync existed (T-039 B.8b).
    public let changedAt: Date?

    public init(name: String, note: String, schedule: [ScheduleEntry], changedAt: Date?) {
        self.name = name
        self.note = note
        self.schedule = schedule.sorted { $0.from < $1.from }
        self.changedAt = changedAt
    }
}

/// One day's done or not done, and when it was set. An uncheck is kept, so it can win over an
/// earlier check-off made on another Mac (T-039 B.10).
public struct Check: Hashable, Sendable {
    public let done: Bool
    public let changedAt: Date?

    public init(done: Bool, changedAt: Date?) {
        self.done = done
        self.changedAt = changedAt
    }
}

/// Something the user does on certain weekdays, tracked as done or not done each day it's due.
/// It carries what merging needs (T-039): when its details and each day changed, and whether it
/// was deleted. `Habits.merge` combines two copies.
public struct Habit: Identifiable, Hashable, Sendable {
    public let id: UUID
    public internal(set) var details: HabitDetails
    /// The day the habit was added. It starts the leaderboard's All time range, but a habit is due on
    /// its scheduled days before it too (T-028). The schedule's first entry normally starts here, but
    /// after the clock moves backward it can start later; that's legal (T-003 E.7).
    public internal(set) var addedOn: Day
    /// The moment it was added: only the list's order (T-039 B.12).
    public internal(set) var createdAt: Date
    /// Set when the habit is deleted. Nothing clears it, so a delete beats every edit (T-039).
    public internal(set) var deletedAt: Date?
    public internal(set) var checks: [Day: Check]

    public init(id: UUID, details: HabitDetails, addedOn: Day, createdAt: Date, deletedAt: Date?, checks: [Day: Check])
    {
        self.id = id
        self.details = details
        self.addedOn = addedOn
        self.createdAt = createdAt
        self.deletedAt = deletedAt
        self.checks = checks
    }

    /// A habit with no change times, as data saved before sync existed reads (T-039 B.8b).
    public init(id: UUID, name: String, note: String, addedOn: Day, schedule: [ScheduleEntry], checkOffs: Set<Day>) {
        self.init(
            id: id, details: HabitDetails(name: name, note: note, schedule: schedule, changedAt: nil), addedOn: addedOn,
            createdAt: .distantPast, deletedAt: nil,
            checks: Dictionary(uniqueKeysWithValues: checkOffs.map { ($0, Check(done: true, changedAt: nil)) }))
    }

    public var name: String { details.name }
    public var note: String { details.note }
    public var schedule: [ScheduleEntry] { details.schedule }
    public var isDeleted: Bool { deletedAt != nil }

    /// The days checked off.
    public var checkOffs: Set<Day> {
        Set(checks.compactMap { $0.value.done ? $0.key : nil })
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

    /// Due on a scheduled weekday, or on any day that's checked off: a check-off records something the
    /// person did, so a schedule change from another Mac never turns it into "not scheduled" (T-039 B.21).
    public func isDue(on day: Day) -> Bool {
        isScheduled(on: day) || isDone(on: day)
    }

    /// Whether the schedule alone includes `day`.
    public func isScheduled(on day: Day) -> Bool {
        days(on: day).contains(day.weekday)
    }

    public func isDone(on day: Day) -> Bool {
        checks[day]?.done == true
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
