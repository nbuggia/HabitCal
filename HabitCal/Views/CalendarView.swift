import HabitCalKit
import SwiftUI

/// The month calendar: header with paging, weekday initials, and six weeks of days (T-002 B.6–B.10).
struct CalendarView: View {
    @Environment(AppModel.self) private var model

    /// Fixed columns, centered, so the days sit close together instead of spreading across the popover
    /// (T-006, T-020). The header shares the grid's width, so its title and arrows line up with it.
    private static let columnWidth: CGFloat = 28
    private static let columnSpacing: CGFloat = 2
    private static let gridWidth = columnWidth * 7 + columnSpacing * 6
    private let columns = Array(repeating: GridItem(.fixed(columnWidth), spacing: columnSpacing), count: 7)

    var body: some View {
        VStack(spacing: 6) {
            header
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(model.weekStart.orderedWeekdays, id: \.self) { weekday in
                    Text(MonthNames.weekdayInitial(weekday))
                        // Bold and primary so it stays readable on the popover's Liquid Glass (T-010).
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.primary)
                        .accessibilityHidden(true)
                }
                ForEach(model.gridDays, id: \.self) { day in
                    DayCell(day: day, isToday: day == model.today, inMonth: model.displayedMonth.contains(day))
                }
            }
        }
        .frame(width: Self.gridWidth)
        .frame(maxWidth: .infinity)
    }

    private var header: some View {
        HStack {
            Text(model.displayedMonth.title)
                .font(.headline)
                .accessibilityIdentifier("calendarTitle")
            Spacer()
            HStack(spacing: 2) {
                navButton("caret-left", label: "Previous month") { model.showPreviousMonth() }
                navButton("calendar-dot", label: "Today") { model.showToday() }
                navButton("caret-right", label: "Next month") { model.showNextMonth() }
            }
        }
    }

    private func navButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            PhosphorIcon(icon, size: 14)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(label)
        .help(label)
    }
}

private struct DayCell: View {
    let day: Day
    let isToday: Bool
    let inMonth: Bool

    var body: some View {
        Text("\(day.day)")
            .font(.system(size: 11, weight: isToday ? .bold : .medium).monospacedDigit())
            .foregroundStyle(
                isToday ? AnyShapeStyle(.white) : inMonth ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary)
            )
            .frame(width: 20, height: 20)
            .background {
                if isToday {
                    // A rounded square in the menu bar icon's proportions (4.95 pt corners on 21 pt) (T-013).
                    RoundedRectangle(cornerRadius: 4.7).fill(Color.accentColor)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 24)
            .accessibilityElement()
            .accessibilityLabel(MonthNames.spokenCalendarDay(day, isToday: isToday))
    }
}
