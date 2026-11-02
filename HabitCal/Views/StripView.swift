import HabitCalKit
import SwiftUI

/// A habit's last 30 due days, oldest first, ending at the day the list shows, which carries the
/// ring (T-041). Display only: no tap, no keyboard focus, and hidden from VoiceOver, since past days
/// are fixed from the calendar and the done button (T-022) and the row already speaks for the habit.
struct StripView: View {
    @Environment(AppModel.self) private var model
    let habit: Habit

    var body: some View {
        let strip = habit.dueStrip(endingAt: model.shownDay, today: model.today)
        HStack(spacing: 1.5) {
            ForEach(Array(strip.enumerated()), id: \.offset) { _, square in
                StripSquare(square: square)
                    // The ring is wider than the square; draw it above the neighbors (T-007).
                    .zIndex(square?.isShown == true ? 1 : 0)
                    .help(square.map(HabitLabels.stripTooltip) ?? "")
            }
        }
        .accessibilityHidden(true)
    }
}

private struct StripSquare: View {
    /// Nil for a slot with no due day (T-041 E.5).
    let square: DueSquare?

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(fill)
            .overlay {
                RoundedRectangle(cornerRadius: 2).strokeBorder(outline, lineWidth: 1)
            }
            .overlay {
                if square?.isShown == true {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.accentColor, lineWidth: 1.5)
                        .padding(-1.5)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
    }

    private var fill: Color {
        switch square?.state {
        case .done: .green
        case .missed: .red.opacity(0.28)
        // Before the habit was added: faint, so it doesn't read as a failure (T-041 B.5a).
        case .beforeAdded: .secondary.opacity(0.18)
        case .future, nil: .clear
        }
    }

    private var outline: Color {
        square?.state == .future ? .secondary.opacity(0.7) : .clear
    }
}
