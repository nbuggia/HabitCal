import Testing

@testable import HabitCalKit

@Suite("Habits")
struct HabitSuggestionTests {
    @Test func fourteenDistinctSuggestionsThatFitTheNameField() {
        #expect(HabitSuggestion.all.count == 14)
        #expect(Set(HabitSuggestion.all.map(\.name)).count == 14)
        // "e.g. " plus the name has to fit the 200 pt field without truncating.
        #expect(HabitSuggestion.all.allSatisfy { $0.name.count <= 21 })
        #expect(HabitSuggestion.all.allSatisfy { !$0.note.isEmpty && $0.note.count <= 60 })
    }

    @Test func theNextSuggestionIsNeverTheOneJustShown() {
        for last in HabitSuggestion.all {
            for pick in 0..<(HabitSuggestion.all.count - 1) {
                #expect(HabitSuggestion.next(after: last, random: { _ in pick }) != last)
            }
        }
        #expect(HabitSuggestion.all.contains(HabitSuggestion.next(after: nil)))
    }
}
