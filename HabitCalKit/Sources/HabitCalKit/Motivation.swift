/// The leaderboard's nudge when nothing in the range is due yet: the first day of a week, month,
/// or year, before anything is checked off (customer, 2026-11-13).
public enum Motivation {
    public static let messages = [
        "Go get it!",
        "Fresh start. Make it count!",
        "Day one. Let's go!",
        "Clean slate. Your move!",
        "First check-off wins the day!",
        "Let's get this streak going!",
        "Do one today. Thank yourself later!",
        "One check-off starts a streak!",
    ]

    /// A random message, never the one shown last. `random(n)` returns a number in 0..<n; tests
    /// pass a fixed one.
    public static func next(after last: String?, random: (Int) -> Int = { Int.random(in: 0..<$0) }) -> String {
        let choices = messages.filter { $0 != last }
        return choices[random(choices.count)]
    }
}
