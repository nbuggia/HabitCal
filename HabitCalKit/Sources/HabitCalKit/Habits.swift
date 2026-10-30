import Foundation

/// What the habit form edits.
public struct HabitDraft: Equatable, Sendable {
    public static let maxNameLength = 40
    public static let maxNoteLength = 280

    public var name: String
    public var note: String
    public var days: Set<Int>

    public init(name: String, note: String, days: Set<Int>) {
        self.name = name
        self.note = note
        self.days = days
    }

    /// Add or Save is enabled only with a name and at least one day (T-003 B.10).
    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !days.isEmpty
    }

    /// Leading and trailing spaces removed (B.11).
    public var trimmed: HabitDraft {
        HabitDraft(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines), days: days)
    }

    /// Name and note cut to their limits (E.4).
    public var clamped: HabitDraft {
        HabitDraft(
            name: String(name.prefix(Self.maxNameLength)), note: String(note.prefix(Self.maxNoteLength)), days: days)
    }
}

/// The user's habits, in the order they were added. Every change takes `today`, so the rules
/// about schedules and check-offs never read the clock themselves.
public struct Habits: Equatable, Sendable {
    public private(set) var all: [Habit]

    public init(_ all: [Habit] = []) {
        self.all = all
    }

    public subscript(id: UUID) -> Habit? {
        all.first { $0.id == id }
    }

    /// The habits due on a day, in the order added: the list's rows (T-012 B.1).
    public func dueOn(_ day: Day) -> [Habit] {
        all.filter { $0.isDue(on: day) }
    }

    /// The habits not due on a day, in the order added: the folded row's rows (T-012 B.2).
    public func notDueOn(_ day: Day) -> [Habit] {
        all.filter { !$0.isDue(on: day) }
    }

    /// Adds a habit due from today, at the bottom of the list (B.11, B.14).
    @discardableResult
    public mutating func add(_ draft: HabitDraft, today: Day) -> UUID {
        let draft = draft.clamped.trimmed
        let habit = Habit(
            id: UUID(), name: draft.name, note: draft.note, addedOn: today,
            schedule: [ScheduleEntry(from: today, days: draft.days)], checkOffs: [])
        all.append(habit)
        return habit.id
    }

    /// Renames, re-notes, and re-schedules a habit. A schedule change applies from today: entries
    /// starting today or later are replaced, so the last change of a day wins (B.2, B.3). If today is
    /// no longer due, today's check-off is removed (B.13).
    public mutating func update(_ id: UUID, with draft: HabitDraft, today: Day) {
        guard let index = all.firstIndex(where: { $0.id == id }) else { return }
        let draft = draft.clamped.trimmed
        var habit = all[index]
        habit.name = draft.name
        habit.note = draft.note
        if draft.days != habit.days(today: today) {
            habit.schedule = habit.schedule.filter { $0.from < today } + [ScheduleEntry(from: today, days: draft.days)]
            if !habit.isDue(on: today) {
                habit.checkOffs.remove(today)
            }
        }
        all[index] = habit
    }

    /// Deletes a habit with its schedule history and check-offs (B.16).
    public mutating func delete(_ id: UUID) {
        all.removeAll { $0.id == id }
    }

    /// Toggles `day` between done and not done, only for a due day up to today (B.4–B.6).
    /// Returns whether anything changed.
    @discardableResult
    public mutating func toggle(_ id: UUID, on day: Day, today: Day) -> Bool {
        guard let index = all.firstIndex(where: { $0.id == id }), day <= today, all[index].isDue(on: day) else {
            return false
        }
        if all[index].checkOffs.contains(day) {
            all[index].checkOffs.remove(day)
        } else {
            all[index].checkOffs.insert(day)
        }
        return true
    }
}
