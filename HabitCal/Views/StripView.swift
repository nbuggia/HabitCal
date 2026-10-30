import HabitCalKit
import SwiftUI

/// A habit's month: one square per day of the displayed month (T-003 §5). One Tab stop: ← / → move
/// a cursor and Space toggles its day; VoiceOver adjusts the same cursor and toggles with its
/// default action (E.8).
struct StripView: View {
    @Environment(AppModel.self) private var model
    let habit: Habit
    @State private var cursorDay: Day?
    @FocusState private var focused: Bool

    var body: some View {
        let month = model.displayedMonth
        let strip = habit.strip(for: month, today: model.today)
        let cursor = cursor(in: month)
        HStack(spacing: 1.5) {
            ForEach(0..<strip.count, id: \.self) { index in
                square(strip[index], number: index + 1, month: month, isCursor: focused && cursor.day == index + 1)
            }
        }
        .focusable(interactions: .edit)
        .focusEffectDisabled()
        .focused($focused)
        .onKeyPress(.leftArrow) {
            move(by: -1, in: month)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            move(by: 1, in: month)
            return .handled
        }
        .onKeyPress(.space) {
            model.toggle(habit.id, on: cursor)
            return .handled
        }
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("strip-\(habit.name)")
        .accessibilityLabel("\(habit.name), \(month.title)")
        .accessibilityValue(HabitLabels.stripSpoken(cursor, state(of: cursor, in: strip)))
        .accessibilityAdjustableAction { direction in
            move(by: direction == .increment ? 1 : -1, in: month)
        }
        .accessibilityAction {
            model.toggle(habit.id, on: cursor)
        }
    }

    /// The cursor's day: the last day used in this month, otherwise today if it's in the month, otherwise the 1st.
    private func cursor(in month: Month) -> Day {
        if let cursorDay, month.contains(cursorDay) { return cursorDay }
        return month.contains(model.today) ? model.today : month.firstDay
    }

    private func move(by offset: Int, in month: Month) {
        let next = cursor(in: month).adding(days: offset)
        if month.contains(next) { cursorDay = next }
    }

    private func state(of day: Day, in strip: [StripDay]) -> StripDay {
        strip[day.day - 1]
    }

    @ViewBuilder
    private func square(_ state: StripDay, number: Int, month: Month, isCursor: Bool) -> some View {
        let day = Day(year: month.year, month: month.month, day: number)
        StripSquare(state: state, isToday: day == model.today, isCursor: isCursor)
            // The ring is wider than the square; draw it above the neighbors (T-007).
            .zIndex(day == model.today || isCursor ? 1 : 0)
            .help(state == .blank ? "" : HabitLabels.stripTooltip(day, state))
            .onTapGesture {
                guard state != .blank else { return }
                cursorDay = day
                model.toggle(habit.id, on: day)
            }
    }
}

private struct StripSquare: View {
    let state: StripDay
    let isToday: Bool
    let isCursor: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(fill)
            .overlay {
                RoundedRectangle(cornerRadius: 2).strokeBorder(outline, lineWidth: 1)
            }
            .overlay {
                if isToday || isCursor {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.accentColor, lineWidth: isCursor ? 2 : 1.5)
                        .padding(-1.5)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
    }

    private var fill: Color {
        switch state {
        case .done: .green
        case .missed: .red.opacity(0.28)
        case .notScheduled: .secondary.opacity(0.18)
        case .future, .futureNotScheduled, .blank: .clear
        }
    }

    private var outline: Color {
        switch state {
        case .future: .secondary.opacity(0.7)
        case .futureNotScheduled: .secondary.opacity(0.3)
        default: .clear
        }
    }
}
