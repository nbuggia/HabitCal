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
            Text(header(for: model.shownDay))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .lineLimit(1)
                .accessibilityLabel(HabitLabels.listHeaderSpoken(day: model.shownDay, today: model.today))
                .accessibilityIdentifier("habitsSection")
            headerButton("plus-circle", size: 17, label: "Add habit") { model.openAddForm() }
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
                    // The shown day's habits; the rest fold into a row under them (T-012, T-022).
                    let onToday = model.shownDay == model.today
                    let due = model.habits.dueOn(model.shownDay)
                    let notDue = model.habits.notDueOn(model.shownDay)
                    ForEach(due) { habit in
                        HabitRow(habit: habit)
                    }
                    if due.isEmpty {
                        Text(HabitLabels.nothingDue(onToday: onToday))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    if !notDue.isEmpty {
                        notDueRow(count: notDue.count, onToday: onToday)
                        if model.showsNotDue {
                            ForEach(notDue) { habit in
                                HabitRow(habit: habit)
                            }
                        }
                    }
                }
                // Room inside the scroll view's clip for what draws past a row's edges: today's
                // strip ring (about 2 pt) and hover highlights (3 pt) (T-018).
                .padding(.vertical, 3)
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

    /// "Habits", or "Habits · Fri, Oct 23" while another day is selected (T-022).
    private func header(for day: Day) -> String {
        guard let date = HabitLabels.listHeader(day: day, today: model.today) else { return "Habits" }
        return "Habits · \(date)"
    }

    private func notDueRow(count: Int, onToday: Bool) -> some View {
        Button {
            model.toggleNotDue()
        } label: {
            HStack(spacing: 4) {
                Text(HabitLabels.notDueRowTitle(count: count, onToday: onToday))
                PhosphorIcon(model.showsNotDue ? "caret-down" : "caret-right", size: 11)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.hover(outset: 3))
        .accessibilityLabel(HabitLabels.notDueRowSpoken(count: count, onToday: onToday))
        .accessibilityValue(model.showsNotDue ? "expanded" : "collapsed")
    }
}
