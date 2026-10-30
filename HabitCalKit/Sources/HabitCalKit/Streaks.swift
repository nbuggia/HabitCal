/// Current and best streaks, counting only the days a habit was due (T-004). A day the habit wasn't
/// scheduled never breaks a streak, and today doesn't break it until the day is over.
public enum Streaks {
    /// A current streak this long is shown in flame-orange.
    public static let hotThreshold = 3

    /// The unbroken run of done due days, walking back from today. Today counts if it's done and is
    /// skipped if it isn't yet; the first earlier due day that wasn't done ends the run (B.1, B.2).
    public static func current(_ habit: Habit, today: Day) -> Int {
        var count = 0
        var day = today
        while day >= habit.addedOn {
            if habit.isDue(on: day) {
                if habit.isDone(on: day) {
                    count += 1
                } else if day != today {
                    break
                }
            }
            day = day.adding(days: -1)
        }
        return count
    }

    /// The longest unbroken run of done due days from the day the habit was added to today, including
    /// the current one. Each past day is judged by the schedule in force on it (B.3, B.4).
    public static func best(_ habit: Habit, today: Day) -> Int {
        var best = 0
        var run = 0
        var day = habit.addedOn
        while day <= today {
            if habit.isDue(on: day) {
                if habit.isDone(on: day) {
                    run += 1
                    best = max(best, run)
                } else if day != today {
                    run = 0
                }
            }
            day = day.adding(days: 1)
        }
        return best
    }

    /// "Current streak 12 days, best streak 30 days" (T-004 E.4).
    public static func spoken(current: Int, best: Int) -> String {
        "Current streak \(days(current)), best streak \(days(best))"
    }

    private static func days(_ count: Int) -> String {
        count == 1 ? "1 day" : "\(count) days"
    }
}
