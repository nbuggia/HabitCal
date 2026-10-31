import Foundation

/// The leaderboard's ranges: rolling windows ending today (T-016 B.2).
public enum ConsistencyRange: CaseIterable, Hashable, Sendable {
    case past7, past30, allTime

    public var title: String {
        switch self {
        case .past7: "Past 7 days"
        case .past30: "Past 30 days"
        case .allTime: "All time"
        }
    }

    /// The first day in the range, or nil for all time.
    func start(today: Day) -> Day? {
        switch self {
        case .past7: today.adding(days: -6)
        case .past30: today.adding(days: -29)
        case .allTime: nil
        }
    }
}

/// Due days checked off, out of due days, over a range.
public struct ConsistencyTally: Equatable, Sendable {
    public let done: Int
    public let due: Int

    public init(done: Int, due: Int) {
        self.done = done
        self.due = due
    }

    /// Nil when nothing was due, so it can't be ranked.
    public var share: Double? {
        due == 0 ? nil : Double(done) / Double(due)
    }
}

public struct ConsistencyEntry: Sendable {
    public let habit: Habit
    public let tally: ConsistencyTally
}

/// The consistency leaderboard: habits ranked by the share of their due days done (T-016).
public enum Consistency {
    /// Today counts only once it's done, so a habit isn't marked down before the day is over (B.3).
    public static func tally(_ habit: Habit, range: ConsistencyRange, today: Day) -> ConsistencyTally {
        var day = max(range.start(today: today) ?? habit.addedOn, habit.addedOn)
        var done = 0
        var due = 0
        while day <= today {
            if habit.isDue(on: day) && (day < today || habit.isDone(on: day)) {
                due += 1
                if habit.isDone(on: day) {
                    done += 1
                }
            }
            day = day.adding(days: 1)
        }
        return ConsistencyTally(done: done, due: due)
    }

    /// Highest share first; ties keep the order added; habits with nothing due come last (B.4).
    public static func board(_ habits: [Habit], range: ConsistencyRange, today: Day) -> [ConsistencyEntry] {
        let entries = habits.map { ConsistencyEntry(habit: $0, tally: tally($0, range: range, today: today)) }
        return entries.enumerated().sorted { a, b in
            switch (a.element.tally.share, b.element.tally.share) {
            case (let x?, let y?) where x != y: x > y
            case (_?, nil): true
            case (nil, _?): false
            default: a.offset < b.offset
            }
        }.map(\.element)
    }

    /// Every habit's due days pooled, so the score is the share of all due days done (B.5).
    public static func overall(_ entries: [ConsistencyEntry]) -> ConsistencyTally {
        ConsistencyTally(
            done: entries.reduce(0) { $0 + $1.tally.done }, due: entries.reduce(0) { $0 + $1.tally.due })
    }

    /// "93%", or "—" when nothing was due.
    public static func percentText(_ tally: ConsistencyTally) -> String {
        guard let percent = percent(tally) else { return "—" }
        return "\(percent)%"
    }

    /// "1st, Read, 93 percent" (B.8).
    public static func rowSpoken(rank: Int, name: String, tally: ConsistencyTally) -> String {
        let ordinal = ordinals.string(from: NSNumber(value: rank)) ?? "\(rank)"
        guard let percent = percent(tally) else { return "\(ordinal), \(name), no due days" }
        return "\(ordinal), \(name), \(percent) percent"
    }

    /// "74 percent of due days done across all habits".
    public static func scoreSpoken(_ tally: ConsistencyTally) -> String {
        guard let percent = percent(tally) else { return "No due days yet" }
        return "\(percent) percent of due days done across all habits"
    }

    /// Rounded, but 100% only for a perfect record and 0% only when nothing was done, so the
    /// number never contradicts the ranking (B.5).
    private static func percent(_ tally: ConsistencyTally) -> Int? {
        guard let share = tally.share else { return nil }
        let rounded = Int((share * 100).rounded())
        if tally.done == tally.due || tally.done == 0 { return rounded }
        return min(max(rounded, 1), 99)
    }

    /// English-only, like the rest of the app (T-002).
    private static let ordinals: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
}
