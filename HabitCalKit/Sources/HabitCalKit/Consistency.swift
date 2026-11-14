import Foundation

/// The leaderboard's ranges: calendar periods to date, each ending today (customer, 2026-11-13).
public enum ConsistencyRange: CaseIterable, Hashable, Sendable {
    case week, month, year

    /// The tab's text: one word, so the three tabs fit the narrow popover.
    public var title: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        case .year: "Year"
        }
    }

    /// What the range covers, shown with the score: "Monday to date" follows the week start setting.
    public func caption(weekStart: WeekStart) -> String {
        switch self {
        case .week: weekStart == .monday ? "Monday to date" : "Sunday to date"
        case .month: "Month to date"
        case .year: "Year to date"
        }
    }

    /// What VoiceOver reads for the tab: "Week, Monday to date".
    public func spoken(weekStart: WeekStart) -> String {
        "\(title), \(caption(weekStart: weekStart))"
    }

    /// The first day of the period containing `today`: the week's first day under `weekStart`, the
    /// 1st of the month, or January 1.
    public func start(today: Day, weekStart: WeekStart) -> Day {
        switch self {
        case .week: today.adding(days: -((today.weekday - weekStart.weekday + 7) % 7))
        case .month: Day(year: today.year, month: today.month, day: 1)
        case .year: Day(year: today.year, month: 1, day: 1)
        }
    }

    /// The last day of the period containing `today`.
    public func end(today: Day, weekStart: WeekStart) -> Day {
        switch self {
        case .week:
            return start(today: today, weekStart: weekStart).adding(days: 6)
        case .month:
            let next =
                today.month == 12
                ? Day(year: today.year + 1, month: 1, day: 1)
                : Day(year: today.year, month: today.month + 1, day: 1)
            return next.adding(days: -1)
        case .year:
            return Day(year: today.year, month: 12, day: 31)
        }
    }

    /// The leaderboard's message when there are no habits yet, one per tab (customer, 2026-11-13).
    /// The week's and month's break onto two lines by design; VoiceOver reads each as one line.
    public var noHabitsMessage: String {
        switch self {
        case .week: "Start a habit\ntoday!"
        case .month: "Give it a month,\nsee what happens!"
        case .year: "Imagine what you could do in a year!"
        }
    }

    /// The score box's "Since" figure: the period's first day, "11/9" (customer, 2026-11-13).
    public func startText(today: Day, weekStart: WeekStart) -> String {
        let start = start(today: today, weekStart: weekStart)
        return "\(start.month)/\(start.day)"
    }

    /// The score box's days-left figure and its label: the days after today left in the period,
    /// ("2", "days left"), ("1", "day left"), or ("Last", "day") on its last day.
    public func daysLeftFigure(today: Day, weekStart: WeekStart) -> (value: String, label: String) {
        switch daysLeft(today: today, weekStart: weekStart) {
        case 0: ("Last", "day")
        case 1: ("1", "day left")
        case let left: ("\(left)", "days left")
        }
    }

    /// What VoiceOver reads after the score: "Since November 9, 2 days left".
    public func periodSpoken(today: Day, weekStart: WeekStart) -> String {
        let start = start(today: today, weekStart: weekStart)
        let left = daysLeftFigure(today: today, weekStart: weekStart)
        return "Since \(MonthNames.name(of: start.month)) \(start.day), \(left.value) \(left.label)"
    }

    func daysLeft(today: Day, weekStart: WeekStart) -> Int {
        var day = today
        var count = 0
        let last = end(today: today, weekStart: weekStart)
        while day < last {
            day = day.adding(days: 1)
            count += 1
        }
        return count
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
    /// A range starts at its period's first day, or later if the habit started later: when it was
    /// added, or at an earlier check-off. Days before a habit existed don't count against it, so one
    /// added in November isn't scored over the whole year (customer, 2026-11-13; was T-028 B.4).
    public static func tally(
        _ habit: Habit, range: ConsistencyRange, today: Day, weekStart: WeekStart
    ) -> ConsistencyTally {
        var day = max(
            range.start(today: today, weekStart: weekStart), min(habit.addedOn, habit.trackedFrom(today: today)))
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
    public static func board(
        _ habits: [Habit], range: ConsistencyRange, today: Day, weekStart: WeekStart
    ) -> [ConsistencyEntry] {
        let entries = habits.map {
            ConsistencyEntry(habit: $0, tally: tally($0, range: range, today: today, weekStart: weekStart))
        }
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

    /// A leaderboard row's first detail line: "12 events · 9 completed" (customer, 2026-11-13). An
    /// event is a due day in the range; today counts once it's done, as in the tally.
    public static func eventsText(_ tally: ConsistencyTally) -> String {
        "\(tally.due) \(tally.due == 1 ? "event" : "events") · \(tally.done) completed"
    }

    /// A leaderboard row's second detail line: the habit's current streak, "5 streak".
    public static func streakText(_ current: Int) -> String {
        "\(current) streak"
    }

    /// What VoiceOver reads after the row's label: "12 events, 9 completed, 5 streak".
    public static func detailSpoken(_ tally: ConsistencyTally, streak: Int) -> String {
        "\(tally.due) \(tally.due == 1 ? "event" : "events"), \(tally.done) completed, \(streakText(streak))"
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
