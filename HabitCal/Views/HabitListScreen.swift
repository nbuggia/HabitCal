import SwiftUI

/// The calendar, the habits under it, and the footer.
struct HabitListScreen: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CalendarView()
            Divider()
            Text("Habits")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .accessibilityIdentifier("habitsSection")
            Divider()
            HStack {
                Spacer()
                Button {
                    model.openSettings()
                } label: {
                    PhosphorIcon("gear-six", size: 16)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Settings")
            }
        }
        .padding(12)
    }
}
