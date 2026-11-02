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

/// What a merge changed: the habits that differ here now, and the ones iCloud should get because the
/// result differs from what came in (T-039).
public struct MergeResult: Equatable, Sendable {
    public var changed: Set<UUID> = []
    public var toSend: Set<UUID> = []
}

/// The user's habits. Every change takes `today` and `now`, so the rules about schedules, check-offs,
/// and change times never read the clock themselves (T-039 B.10).
public struct Habits: Equatable, Sendable {
    /// Every stored habit, deleted ones included, in list order (`createdAt`, then ID: the same on
    /// every Mac, T-039 B.12). Only `HabitStore`, merging, and sync read it.
    public private(set) var records: [Habit]

    /// The habits shown, in list order. Every screen reads this.
    public var all: [Habit] {
        records.filter { !$0.isDeleted }
    }

    public init(_ records: [Habit] = []) {
        self.records = Self.ordered(records)
    }

    /// A shown habit by ID; nil once it's deleted.
    public subscript(id: UUID) -> Habit? {
        records.first { $0.id == id && !$0.isDeleted }
    }

    /// The habits due on a day, in list order: the list's rows (T-012 B.1, T-036).
    public func dueOn(_ day: Day) -> [Habit] {
        all.filter { $0.isDue(on: day) }
    }

    // MARK: Local changes

    /// Adds a habit, added today, at the bottom of the list (B.11, B.14). Its `createdAt` is just after
    /// the latest habit's, so it goes last even if the clock moved backward.
    @discardableResult
    public mutating func add(_ draft: HabitDraft, today: Day, now: Date) -> UUID {
        let draft = draft.clamped.trimmed
        let stamp = Self.stamp(now)
        let after = Self.stamp((records.map(\.createdAt).max() ?? .distantPast).addingTimeInterval(0.001))
        let habit = Habit(
            id: UUID(),
            details: HabitDetails(
                name: draft.name, note: draft.note, schedule: [ScheduleEntry(from: today, days: draft.days)],
                changedAt: stamp),
            addedOn: today, createdAt: max(stamp, after), deletedAt: nil, checks: [:])
        records.append(habit)
        return habit.id
    }

    /// Renames, re-notes, and re-schedules a habit. A schedule change applies from today: entries
    /// starting today or later are replaced, so the last change of a day wins (B.2, B.3). If today is
    /// no longer scheduled, today's check-off is removed (B.13). Does nothing if nothing differs, so
    /// re-saving the same values doesn't make a newer change.
    public mutating func setDetails(_ id: UUID, _ draft: HabitDraft, today: Day, now: Date) {
        guard let index = shownIndex(id) else { return }
        let draft = draft.clamped.trimmed
        var habit = records[index]
        var schedule = habit.schedule
        if draft.days != habit.days(today: today) {
            var past = schedule.filter { $0.from < today }
            if past.isEmpty {
                // Every entry starts today or later, but past days are due too (T-028): pin the old
                // days to them, or the new schedule would apply backward through the first-entry rule.
                past = [ScheduleEntry(from: today.adding(days: -1), days: habit.days(today: today))]
            }
            schedule = past + [ScheduleEntry(from: today, days: draft.days)]
        }
        guard draft.name != habit.name || draft.note != habit.note || schedule != habit.schedule else { return }
        let stamp = Self.stamp(now)
        habit.details = HabitDetails(name: draft.name, note: draft.note, schedule: schedule, changedAt: stamp)
        if !habit.isScheduled(on: today) && habit.isDone(on: today) {
            habit.checks[today] = Check(done: false, changedAt: stamp)
        }
        records[index] = habit
    }

    /// The Edit form's change (T-038, T-039 B.11): writes the form's name, note, and days whole, and
    /// leaves check-offs and other habits as they are, so changes to them from another Mac stay. An
    /// invalid draft (no name or no days) isn't saved. If today was done when the form opened and its
    /// weekday comes back, today is checked off again: unticking a day and ticking it back undoes nothing.
    public mutating func applyFormEdit(_ id: UUID, draft: HabitDraft, todayDoneAtOpen: Bool, today: Day, now: Date) {
        guard draft.isValid else { return }
        setDetails(id, draft, today: today, now: now)
        guard todayDoneAtOpen, let index = shownIndex(id), records[index].isScheduled(on: today),
            !records[index].isDone(on: today)
        else { return }
        records[index].checks[today] = Check(done: true, changedAt: Self.stamp(now))
    }

    /// Deletes a habit with its schedule history and check-offs (B.16). It stays as a record, so the
    /// delete reaches other Macs and beats their edits (T-039).
    public mutating func delete(_ id: UUID, now: Date) {
        guard let index = shownIndex(id) else { return }
        records[index].deletedAt = Self.stamp(now)
    }

    /// Toggles `day` between done and not done, only for a due day up to today (B.4–B.6).
    /// Returns whether anything changed.
    @discardableResult
    public mutating func toggle(_ id: UUID, on day: Day, today: Day, now: Date) -> Bool {
        guard let index = shownIndex(id), day <= today, records[index].isDue(on: day) else { return false }
        records[index].checks[day] = Check(done: !records[index].isDone(on: day), changedAt: Self.stamp(now))
        return true
    }

    /// An import (T-035, T-039 B.13): deletes every habit shown and adds the file's habits as new
    /// habits, with new IDs, in the file's order. A restore is then ordinary deletes and adds on every
    /// Mac, so a habit another Mac added that this one didn't know survives it.
    /// Returns the habits it deleted and added, for sync to send (T-039 B.13).
    @discardableResult
    public mutating func replaceAll(with habits: [Habit], now: Date) -> Set<UUID> {
        let stamp = Self.stamp(now)
        var changed: Set<UUID> = []
        for index in records.indices where !records[index].isDeleted {
            records[index].deletedAt = stamp
            changed.insert(records[index].id)
        }
        for (offset, habit) in habits.enumerated() {
            let id = UUID()
            changed.insert(id)
            records.append(
                Habit(
                    id: id,
                    details: HabitDetails(
                        name: habit.name, note: habit.note, schedule: habit.schedule, changedAt: stamp),
                    addedOn: habit.addedOn, createdAt: Self.stamp(stamp.addingTimeInterval(Double(offset) * 0.001)),
                    deletedAt: nil,
                    checks: habit.checks.filter(\.value.done).mapValues { _ in Check(done: true, changedAt: stamp) }))
        }
        records = Self.ordered(records)
        return changed
    }

    // MARK: Merging (T-039)

    /// Merges habits from iCloud into these. Per habit: the later details win, each day's later check
    /// wins, a delete on either side wins, and the earlier added date and creation moment are kept. It's
    /// commutative, associative, and idempotent, so every Mac ends up the same whatever order changes
    /// arrive in. No check is ever ignored, so a merge can't hide a check-off (B.21).
    @discardableResult
    public mutating func merge(_ remote: [Habit]) -> MergeResult {
        var result = MergeResult()
        var byID = Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
        for incoming in remote {
            let merged = byID[incoming.id].map { Self.merged($0, incoming) } ?? incoming
            if byID[incoming.id] != merged { result.changed.insert(incoming.id) }
            if merged != incoming { result.toSend.insert(incoming.id) }
            byID[incoming.id] = merged
        }
        records = Self.ordered(Array(byID.values))
        return result
    }

    /// The first sync of this Mac (T-039 B.7–B.9): every habit from either side is kept. Copies of the
    /// same habit, by ID or by name (only habits shown on both sides), become one under the iCloud ID:
    /// check-offs of both, the earlier added date, the details of whichever changed last (or by B.8b,
    /// the copy checked off most recently, else iCloud's), with past days due only where both copies
    /// had them (B.8a). Deleted habits that iCloud never had are dropped, not sent (E.2).
    @discardableResult
    public mutating func mergeFirstSync(remote: [Habit], today: Day, now: Date) -> MergeResult {
        var result = MergeResult()
        let stamp = Self.stamp(now)
        var remoteByID = Dictionary(uniqueKeysWithValues: remote.map { ($0.id, $0) })
        var local = records.filter { !$0.isDeleted || remoteByID[$0.id] != nil }
        var merged: [Habit] = []
        // Pair by name the shown local habits with no iCloud copy of their own.
        var shownRemoteByName: [String: [Habit]] = [:]
        let localIDs = Set(local.map(\.id))
        for habit in remote where !habit.isDeleted && !localIDs.contains(habit.id) {
            shownRemoteByName[Self.nameKey(habit.name), default: []].append(habit)
        }
        for habit in Self.ordered(local) {
            if let copy = remoteByID[habit.id] {
                let pair =
                    habit.isDeleted || copy.isDeleted
                    ? Self.merged(habit, copy) : Self.mergedFirstSync(habit, copy, today: today, now: stamp)
                merged.append(pair)
                remoteByID[habit.id] = nil
                if pair != copy { result.toSend.insert(pair.id) }
                if pair != habit { result.changed.insert(pair.id) }
            } else if !habit.isDeleted, let copy = shownRemoteByName[Self.nameKey(habit.name)]?.first {
                shownRemoteByName[Self.nameKey(habit.name)]?.removeFirst()
                let pair = Self.mergedFirstSync(habit, copy, today: today, now: stamp)
                merged.append(pair)
                remoteByID[copy.id] = nil
                result.changed.formUnion([habit.id, pair.id])
                if pair != copy { result.toSend.insert(pair.id) }
            } else {
                merged.append(habit)
                result.toSend.insert(habit.id)
            }
        }
        local = merged
        for copy in remoteByID.values {
            local.append(copy)
            result.changed.insert(copy.id)
        }
        records = Self.ordered(local)
        return result
    }

    // MARK: Helpers

    private func shownIndex(_ id: UUID) -> Int? {
        records.firstIndex { $0.id == id && !$0.isDeleted }
    }

    /// Change times are kept to the millisecond, as they're saved.
    static func stamp(_ date: Date) -> Date {
        Date(timeIntervalSince1970: (date.timeIntervalSince1970 * 1000).rounded() / 1000)
    }

    static func ordered(_ habits: [Habit]) -> [Habit] {
        habits.sorted { ($0.createdAt, $0.id.uuidString) < ($1.createdAt, $1.id.uuidString) }
    }

    /// Names that differ only in case or surrounding spaces are the same habit (B.9).
    static func nameKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Whether `a` was changed after `b`; nil is older than any time.
    private static func isLater(_ a: Date?, _ b: Date?) -> Bool {
        (a ?? .distantPast) > (b ?? .distantPast)
    }

    private static func sameTime(_ a: Date?, _ b: Date?) -> Bool {
        a == b
    }

    /// A fixed order between two versions of a habit's details made at the same moment, so every Mac
    /// picks the same one: the larger value wins.
    private static func detailsKey(_ d: HabitDetails) -> String {
        ([d.name, d.note] + d.schedule.map { "\($0.from.iso):\($0.days.sorted())" }).joined(separator: "\u{1}")
    }

    static func merged(_ a: Habit, _ b: Habit) -> Habit {
        var result = a
        if isLater(b.details.changedAt, a.details.changedAt)
            || (sameTime(a.details.changedAt, b.details.changedAt) && detailsKey(b.details) > detailsKey(a.details))
        {
            result.details = b.details
        }
        for (day, check) in b.checks {
            guard let mine = a.checks[day] else {
                result.checks[day] = check
                continue
            }
            // Later wins; at the same moment, done wins.
            if isLater(check.changedAt, mine.changedAt) || (sameTime(check.changedAt, mine.changedAt) && check.done) {
                result.checks[day] = check
            }
        }
        result.deletedAt = [a.deletedAt, b.deletedAt].compactMap { $0 }.max()
        result.createdAt = min(a.createdAt, b.createdAt)
        result.addedOn = min(a.addedOn, b.addedOn)
        return result
    }

    /// Two copies of one habit meeting at the first sync (B.8, B.8a, B.8b), under `remote`'s ID.
    private static func mergedFirstSync(_ local: Habit, _ remote: Habit, today: Day, now: Date) -> Habit {
        var result = merged(
            remote,
            Habit(
                id: remote.id, details: local.details, addedOn: local.addedOn, createdAt: local.createdAt,
                deletedAt: local.deletedAt, checks: local.checks))
        let winner: Habit
        if local.details.changedAt != nil || remote.details.changedAt != nil,
            !sameTime(local.details.changedAt, remote.details.changedAt)
        {
            winner = isLater(local.details.changedAt, remote.details.changedAt) ? local : remote
        } else {
            let never = Day(year: 1, month: 1, day: 1)
            winner = (local.checkOffs.max() ?? never) > (remote.checkOffs.max() ?? never) ? local : remote
        }
        // Past days are due only where both copies had them; from today, the winner's days.
        let starts = Set((local.schedule + remote.schedule).map(\.from).filter { $0 < today })
        var schedule: [ScheduleEntry] = []
        for start in starts.sorted() {
            let days = local.days(on: start).intersection(remote.days(on: start))
            if schedule.last?.days != days { schedule.append(ScheduleEntry(from: start, days: days)) }
        }
        schedule.append(ScheduleEntry(from: today, days: winner.days(today: today)))
        // The merge is a change made now, so it wins over both copies when it reaches other Macs.
        result.details = HabitDetails(name: winner.name, note: winner.note, schedule: schedule, changedAt: now)
        return result
    }
}
