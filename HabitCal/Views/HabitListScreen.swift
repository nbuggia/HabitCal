import SwiftUI

/// The calendar, the habits under it, and the footer.
struct HabitListScreen: View {
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
                    // Settings arrive with T-002 slice 4.
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
