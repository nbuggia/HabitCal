import AppKit
import HabitCalKit
import SwiftUI

/// The calendar, the habits under it, and a bottom row holding Add, the leaderboard, and Settings.
struct HabitListScreen: View {
    @Environment(AppModel.self) private var model
    @State private var listHeight: CGFloat = 0

    /// Room left for the habit list, so the popover never runs off the screen (T-003 E.1).
    private var maxListHeight: CGFloat {
        max(120, (NSScreen.main?.visibleFrame.height ?? 800) - 340)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CalendarView()
            Divider()
            if model.dataState == .saveFailed {
                // Shown until a later save succeeds, even if the list is now empty (T-003 E.6).
                Text("Couldn't save — your last change may be lost")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            habitList
            bottomRow
        }
        .padding(.horizontal, PopoverRoot.margin)
        .padding(.vertical, 12)
    }

    /// Add on the left, the leaderboard and Settings at the far end. There is no "Habits" label: the
    /// list sits right under the calendar (T-031, which reverses T-014's header row).
    private var bottomRow: some View {
        HStack(spacing: 6) {
            rowButton("plus-circle", size: 17, label: "Add habit") { model.openAddForm() }
                .disabled(!model.canAddHabits)
            Spacer()
            rowButton("trophy", size: 15, label: "Leaderboard") { model.openLeaderboard() }
                .disabled(!model.canAddHabits)
            rowButton("sliders", size: 16, label: "Settings") { model.openSettings() }
        }
    }

    private func rowButton(
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
            Text("No habits")
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
                // strip ring (about 2 pt) and hover highlights (3 pt), on every side. The ring
                // reaches past the right edge when today is the month's last day (T-018, T-034).
                .padding(3)
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: {
                    listHeight = $0
                }
            }
            .frame(height: min(listHeight, maxListHeight))
            .scrollBounceBehavior(.basedOnSize)
            // Gives back the side padding above, so the rows still line up with the calendar (T-024).
            .padding(.horizontal, -3)
        }
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
