import AppKit
import SwiftUI

/// The calendar, the habits under it, and the footer.
struct HabitListScreen: View {
    @Environment(AppModel.self) private var model
    @State private var listHeight: CGFloat = 0

    /// Room left for the habit list, so the popover never runs off the screen (T-003 E.1).
    private var maxListHeight: CGFloat {
        max(120, (NSScreen.main?.visibleFrame.height ?? 800) - 330)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CalendarView()
            Divider()
            Text("Habits")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .accessibilityIdentifier("habitsSection")
            habitList
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

    @ViewBuilder
    private var habitList: some View {
        if model.habits.all.isEmpty {
            Text("No habits yet. Add one to start a streak.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(model.habits.all) { habit in
                        HabitRow(habit: habit)
                    }
                }
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: {
                    listHeight = $0
                }
            }
            .frame(height: min(listHeight, maxListHeight))
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}
