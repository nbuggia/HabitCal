import AppKit
import HabitCalKit
import SwiftUI

/// The calendar, then the habits under a header row holding Add and Settings.
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
            header
            if model.dataState == .saveFailed {
                // Shown until a later save succeeds, even if the list is now empty (T-003 E.6).
                Text("Couldn't save — your last change may be lost")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            habitList
        }
        .padding(12)
    }

    /// The section label with Add beside it, and the leaderboard and Settings at the far end; there is
    /// no footer (T-014, T-016).
    private var header: some View {
        HStack(spacing: 6) {
            Text("Habits")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .accessibilityIdentifier("habitsSection")
            headerButton("plus", size: 14, label: "Add habit") { model.openAddForm() }
                .disabled(!model.canAddHabits)
            Spacer()
            headerButton("trophy", size: 15, label: "Leaderboard") { model.openLeaderboard() }
                .disabled(!model.canAddHabits)
            headerButton("sliders", size: 16, label: "Settings") { model.openSettings() }
        }
    }

    private func headerButton(
        _ icon: String, size: CGFloat, label: String, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            PhosphorIcon(icon, size: size)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.hover)
        .accessibilityLabel(label)
        .help(label)
    }

    @ViewBuilder
    private var habitList: some View {
        if case .unreadable(let path) = model.dataState {
            // Shown in place of the list; nothing is saved until the file can be read (T-003 E.5, D-004).
            VStack(alignment: .leading, spacing: 4) {
                Text("HabitCal couldn't read your habits")
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)
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
                    // Today's habits; the rest fold into a row under them (T-012).
                    let due = model.habits.dueOn(model.today)
                    let notDue = model.habits.notDueOn(model.today)
                    ForEach(due) { habit in
                        HabitRow(habit: habit)
                    }
                    if due.isEmpty {
                        Text("Nothing due today")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    if !notDue.isEmpty {
                        notDueRow(count: notDue.count)
                        if model.showsNotDue {
                            ForEach(notDue) { habit in
                                HabitRow(habit: habit)
                            }
                        }
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

    private func notDueRow(count: Int) -> some View {
        Button {
            model.toggleNotDue()
        } label: {
            HStack(spacing: 4) {
                Text(HabitLabels.notDueRowTitle(count: count))
                PhosphorIcon(model.showsNotDue ? "caret-down" : "caret-right", size: 11)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.hover(outset: 3))
        .accessibilityLabel(HabitLabels.notDueRowSpoken(count: count))
        .accessibilityValue(model.showsNotDue ? "expanded" : "collapsed")
    }
}
