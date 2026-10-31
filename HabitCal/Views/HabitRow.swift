import HabitCalKit
import SwiftUI

/// One habit: its done button for today, name and schedule, and its month strip (T-003 §5).
struct HabitRow: View {
    @Environment(AppModel.self) private var model
    let habit: Habit
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                DoneButton(habit: habit)
                Button {
                    model.openEditForm(habit.id)
                } label: {
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Text(habit.name).fontWeight(.semibold).lineLimit(1)
                            PhosphorIcon("pencil-simple", size: 11)
                                .foregroundStyle(.secondary)
                                .opacity(hovering ? 1 : 0)
                        }
                        Text(ScheduleLabel.text(for: habit.days(today: model.today)))
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.hover(outset: 3))
                .onHover { hovering = $0 }
                .help("Edit habit")
                .accessibilityLabel(HabitLabels.editSpoken(name: habit.name))
                .accessibilityValue(ScheduleLabel.text(for: habit.days(today: model.today)))
                Spacer(minLength: 0)
                StreakStats(habit: habit)
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

/// The round button that checks off the shown day (today, or the day selected in the calendar);
/// a dashed circle on a day the habit isn't due. Dimmed and inert on a future day (T-022 B.5).
private struct DoneButton: View {
    @Environment(AppModel.self) private var model
    let habit: Habit

    var body: some View {
        let day = model.shownDay
        let due = habit.isDue(on: day)
        let done = habit.isDone(on: day)
        let spoken = HabitLabels.doneButtonSpoken(name: habit.name, day: day, today: model.today, due: due, done: done)
        let tooltip = HabitLabels.doneButtonTooltip(day: day, today: model.today, due: due, done: done)
        if due {
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
            .help(tooltip)
            .accessibilityLabel(spoken)
        } else {
            Circle()
                .strokeBorder(Color.secondary.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2.5]))
                .frame(width: 24, height: 24)
                .help(tooltip)
                .accessibilityElement()
                .accessibilityLabel(spoken)
        }
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
        HStack(spacing: 10) {
            HStack(spacing: 3) {
                // HabitCal's own flame (T-008), in full color once the streak is above 1, grey below (T-025).
                Image("flame")
                    .resizable()
                    .frame(width: 14, height: 14)
                    .saturation(hot ? 1 : 0)
                    .opacity(hot ? 1 : 0.55)
                    .accessibilityHidden(true)
                Text("\(current)")
                    .fontWeight(hot ? .semibold : .regular)
                    .foregroundStyle(hot ? AnyShapeStyle(Color.orange) : AnyShapeStyle(.secondary))
            }
            .help("Current streak")
            HStack(spacing: 3) {
                // Gold while the current streak is the record (T-025).
                PhosphorIcon("trophy", size: 13)
                    .foregroundStyle(record ? AnyShapeStyle(Color.yellow) : AnyShapeStyle(.secondary))
                Text("\(best)")
                    .foregroundStyle(.secondary)
            }
            .help("Best streak")
        }
        .font(.callout.monospacedDigit())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Streaks.spoken(current: current, best: best))
        .accessibilityIdentifier("streaks-\(habit.name)")
    }
}
