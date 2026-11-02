import HabitCalKit
import SwiftUI

/// One habit: its done button for the shown day, name and schedule, streaks, and its strip of due
/// days (T-003 §5, T-041).
struct HabitRow: View {
    @Environment(AppModel.self) private var model
    let habit: Habit
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // The name has its own line, the row's full width; the schedule and streaks share the second.
            HStack(spacing: 8) {
                DoneButton(habit: habit)
                VStack(alignment: .leading, spacing: 1) {
                    Button {
                        model.openEditForm(habit.id)
                    } label: {
                        HStack(spacing: 4) {
                            Text(habit.name).font(.callout.weight(.semibold)).lineLimit(1)
                            PhosphorIcon("pencil-simple", size: 10)
                                .foregroundStyle(.secondary)
                                .opacity(hovering ? 1 : 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.hover(outset: 3))
                    .onHover { hovering = $0 }
                    .help("Edit habit")
                    .accessibilityLabel(HabitLabels.editSpoken(name: habit.name))
                    .accessibilityValue(ScheduleLabel.text(for: habit.days(today: model.today)))
                    HStack(spacing: 6) {
                        Text(ScheduleLabel.text(for: habit.days(today: model.today)))
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Spacer(minLength: 0)
                        StreakStats(habit: habit)
                    }
                    .font(.caption)
                }
            }
            StripView(habit: habit)
                .padding(.leading, 32)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button("Edit…") { model.openEditForm(habit.id) }
            Divider()
            Button("Delete…") { model.openDeleteConfirmation(habit.id) }
        }
    }
}

/// The round button that checks off the shown day (today, or the day selected in the calendar).
/// Only habits due that day are listed (T-036). Dimmed and inert on a future day (T-022 B.5).
private struct DoneButton: View {
    @Environment(AppModel.self) private var model
    let habit: Habit

    var body: some View {
        let day = model.shownDay
        let done = habit.isDone(on: day)
        Button {
            model.toggleShownDay(habit.id)
        } label: {
            ZStack {
                Circle().strokeBorder(done ? Color.clear : Color.secondary, lineWidth: 1.5)
                if done {
                    Circle().fill(Color.green)
                    PhosphorIcon("check", size: 13).foregroundStyle(.white)
                }
            }
            .frame(width: 24, height: 24)
            .contentShape(Circle())
        }
        .buttonStyle(.hover(cornerRadius: 12, overLabel: true))
        .disabled(day > model.today)
        .help(HabitLabels.doneButtonTooltip(day: day, today: model.today, done: done))
        .accessibilityLabel(HabitLabels.doneButtonSpoken(name: habit.name, day: day, today: model.today, done: done))
    }
}

/// The current streak (fire) and best streak (trophy) at the right of a row (T-004 §5).
private struct StreakStats: View {
    @Environment(AppModel.self) private var model
    let habit: Habit

    var body: some View {
        let current = Streaks.current(habit, today: model.today)
        let best = Streaks.best(habit, today: model.today)
        let hot = Streaks.isHot(current: current)
        let record = Streaks.isRecord(current: current, best: best)
        HStack(spacing: 8) {
            HStack(spacing: 2) {
                // HabitCal's own flame (T-008), in full color once the streak is above 1, grey below (T-025).
                Image("flame")
                    .resizable()
                    .frame(width: 11, height: 11)
                    .saturation(hot ? 1 : 0)
                    .opacity(hot ? 1 : 0.55)
                    .accessibilityHidden(true)
                Text("\(current)")
                    .fontWeight(hot ? .semibold : .regular)
                    .foregroundStyle(hot ? AnyShapeStyle(Color.orange) : AnyShapeStyle(.secondary))
            }
            .help("Current streak")
            HStack(spacing: 2) {
                // Gold while the current streak is the record, like the flame's orange (T-025).
                PhosphorIcon("trophy", size: 10)
                Text("\(best)")
                    .fontWeight(record ? .semibold : .regular)
            }
            .foregroundStyle(record ? AnyShapeStyle(Color.yellow) : AnyShapeStyle(.secondary))
            .help("Best streak")
        }
        .font(.caption.monospacedDigit())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Streaks.spoken(current: current, best: best))
        .accessibilityIdentifier("streaks-\(habit.name)")
    }
}
