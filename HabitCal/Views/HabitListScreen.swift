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
            if model.dataState == .saveFailed {
                // Shown until a later save succeeds, even if the list is now empty (T-003 E.6).
                Text("Couldn't save — your last change may be lost")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            habitList
            Divider()
            HStack {
                Button {
                    model.openAddForm()
                } label: {
                    HStack(spacing: 4) {
                        PhosphorIcon("plus", size: 13)
                        Text("Add habit")
                    }
                }
                .buttonStyle(.borderless)
                .disabled(!model.canAddHabits)
                .accessibilityLabel("Add habit")
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
        if case .unreadable(let path) = model.dataState {
            // Shown in place of the list; nothing is saved until the file can be read (T-003 E.5, D-004).
            VStack(alignment: .leading, spacing: 4) {
                Text("HabitCal couldn't read your habits").fontWeight(.semibold)
                Text(path)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
        } else if model.habits.all.isEmpty {
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
