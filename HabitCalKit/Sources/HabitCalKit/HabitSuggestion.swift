/// The examples in the New habit form's empty fields: small, good things anyone can do, chosen by
/// the customer and written in a mom's voice. Each name comes with a matching note (customer,
/// 2026-11-14).
public struct HabitSuggestion: Hashable, Sendable {
    public let name: String
    public let note: String

    public static let all = [
        HabitSuggestion(name: "Push-ups", note: "Ten of them. Before you talk yourself out of it."),
        HabitSuggestion(name: "Read a book", note: "A real one, with pages. Your eyes will survive."),
        HabitSuggestion(name: "Write a letter", note: "With a stamp. Somebody's mailbox needs love."),
        HabitSuggestion(name: "Call a friend", note: "Just to say hi. No agenda required."),
        HabitSuggestion(name: "Write a story", note: "Use there, and, but, so. Go on, I'm listening."),
        HabitSuggestion(name: "Call your mom", note: "She worries. Ten minutes won't kill you."),
        HabitSuggestion(name: "Drink some coffee", note: "One cup. Not the whole pot, dear."),
        HabitSuggestion(name: "Play some music", note: "Loud enough to dance. The neighbors can cope."),
        HabitSuggestion(name: "Daydream", note: "Stare out the window. It's allowed."),
        HabitSuggestion(name: "Do a puzzle", note: "Jigsaw, crossword, sudoku. Keeps you sharp."),
        HabitSuggestion(name: "Do something social", note: "Go see people. In person. With pants on."),
        HabitSuggestion(name: "Turn off all screens", note: "Yes, that one too. Off, not just face down."),
        HabitSuggestion(name: "Write a song", note: "Rhyme moon with June. It's a classic for a reason."),
        HabitSuggestion(name: "Explore somewhere new", note: "A new street, a new park. Text me when you get there."),
    ]

    /// A random suggestion, never the one shown last. `random(n)` returns a number in 0..<n; tests
    /// pass a fixed one.
    public static func next(after last: HabitSuggestion?, random: (Int) -> Int = { Int.random(in: 0..<$0) })
        -> HabitSuggestion
    {
        let choices = all.filter { $0 != last }
        return choices[random(choices.count)]
    }
}
