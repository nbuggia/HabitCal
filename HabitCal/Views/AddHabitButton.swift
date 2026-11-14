import SwiftUI

/// "(+) Habit" at the bottom left of the habit list and the leaderboard: the icon, then "Habit" in
/// the standard font (customer, 2026-11-13). Opens the add form; Close comes back to the screen it
/// was opened from.
struct AddHabitButton: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Button {
            model.openAddForm()
        } label: {
            HStack(spacing: 4) {
                PhosphorIcon("plus-circle", size: 17)
                Text("Habit")
            }
            .frame(height: 22)
            .padding(.trailing, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.hover)
        .disabled(!model.canAddHabits)
        .accessibilityLabel("Add habit")
        .help("Add habit")
    }
}
