import AppKit
import HabitCalKit
import SwiftUI

/// The consistency leaderboard: habits ranked by the share of their due days done (T-016).
struct LeaderboardScreen: View {
    @Environment(AppModel.self) private var model
    @State private var listHeight: CGFloat = 0

    /// Room left for the rows, so the popover never runs off the screen (like the habit list).
    private var maxListHeight: CGFloat {
        max(120, (NSScreen.main?.visibleFrame.height ?? 800) - 240)
    }

    var body: some View {
        let entries = Consistency.board(
            model.habits.all, range: model.leaderboardRange, today: model.today, weekStart: model.weekStart)
        VStack(alignment: .leading, spacing: 10) {
            header
            rangePicker
            if entries.isEmpty {
                // Centered in the space between the tabs and the add button.
                Spacer(minLength: 0)
                noHabits
            } else {
                score(Consistency.overall(entries))
            }
            if !entries.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(entries.enumerated()), id: \.element.habit.id) { index, entry in
                            LeaderboardRow(
                                rank: index + 1, entry: entry, streak: Streaks.current(entry.habit, today: model.today))
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
            // The add button stays at the bottom of the panel, as on the habit list.
            Spacer(minLength: 0)
            AddHabitButton()
        }
        .padding(.horizontal, PopoverRoot.margin)
        .padding(.vertical, 12)
    }

    private var header: some View {
        ZStack {
            Text("Leaderboard").font(.headline)
            HStack {
                Button {
                    model.closeLeaderboard()
                } label: {
                    HStack(spacing: 2) {
                        PhosphorIcon("caret-left", size: 13)
                        Text("Back")
                    }
                }
                .buttonStyle(.hover(outset: 3))
                .accessibilityLabel("Back")
                Spacer()
            }
        }
    }

    /// Three equal tabs. A segmented Picker won't shrink below its labels, which overflowed the
    /// popover and pushed the whole screen against its edges.
    private var rangePicker: some View {
        HStack(spacing: 2) {
            ForEach(ConsistencyRange.allCases, id: \.self) { range in
                RangeTab(
                    title: range.title, spoken: range.spoken(weekStart: model.weekStart),
                    selected: model.leaderboardRange == range
                ) {
                    model.pickLeaderboardRange(range)
                }
            }
        }
        .padding(2)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 7))
    }

    /// No habits: a nudge for the tab (customer, 2026-11-13); the add button is at the bottom.
    private var noHabits: some View {
        // Large, grey like the list's "No habits", on the panel itself: no score box when there's
        // nothing to score.
        Text(model.leaderboardRange.noHabitsMessage)
            .font(.system(size: 22, weight: .regular))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(model.leaderboardRange.noHabitsMessage.replacingOccurrences(of: "\n", with: " "))
            .accessibilityIdentifier("leaderboardNoHabits")
    }

    /// Three equal figures, each a big value over a small grey label: the period's first day, the
    /// days left in it, and the score (customer, 2026-11-13).
    private func score(_ tally: ConsistencyTally) -> some View {
        let range = model.leaderboardRange
        let left = range.daysLeftFigure(today: model.today, weekStart: model.weekStart)
        return VStack(spacing: 6) {
            HStack(spacing: 0) {
                ScoreFigure(value: range.startText(today: model.today, weekStart: model.weekStart), label: "Start")
                Divider().frame(height: 30)
                ScoreFigure(value: left.value, label: left.label)
                Divider().frame(height: 30)
                ScoreFigure(value: Consistency.percentText(tally), label: "Complete")
            }
            // Nothing due yet in the range: a nudge instead of an empty score.
            if tally.due == 0 {
                Text(model.motivation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tally.due == 0 ? model.motivation : Consistency.scoreSpoken(tally))
        .accessibilityValue(range.periodSpoken(today: model.today, weekStart: model.weekStart))
        .accessibilityIdentifier("leaderboardScore")
    }
}

/// One of the score box's figures: a big value over a small grey label, centered in a third.
private struct ScoreFigure: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 0) {
            // 20 pt fits the widest values, "12/31" and "100%" (about 58 pt), in a third of the box.
            Text(value)
                .font(.system(size: 20, weight: .bold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Rank, name over a bar filled to the share, and the percentage. Under the bar, in the habit
/// list's small grey schedule type: the range's events and completions, then the current streak.
private struct LeaderboardRow: View {
    @Environment(AppModel.self) private var model
    @State private var hovering = false
    let rank: Int
    let entry: ConsistencyEntry
    let streak: Int

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            RankShield(rank: rank, perfect: entry.tally.due > 0 && entry.tally.done == entry.tally.due)
                // The shield's outline starts 4 pt into its frame; this puts its top level with the name's.
                .offset(y: -1)
            VStack(alignment: .leading, spacing: 4) {
                // Like the habit list: the name opens the Edit form, with a pencil on hover.
                Button {
                    model.openEditForm(entry.habit.id)
                } label: {
                    HStack(spacing: 4) {
                        Text(entry.habit.name).fontWeight(.semibold).lineLimit(1)
                        PhosphorIcon("pencil-simple", size: 10)
                            .foregroundStyle(.secondary)
                            .opacity(hovering ? 1 : 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.hover(outset: 3))
                .onHover { hovering = $0 }
                .help("Edit habit")
                bar
                VStack(alignment: .leading, spacing: 0) {
                    Text(Consistency.eventsText(entry.tally))
                    Text(Consistency.streakText(streak))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Text(Consistency.percentText(entry.tally))
                .fontWeight(.semibold)
                .monospacedDigit()
                .frame(minWidth: 38, alignment: .trailing)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button("Edit…") { model.openEditForm(entry.habit.id) }
            Divider()
            Button("Delete…") { model.openDeleteConfirmation(entry.habit.id) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Consistency.rowSpoken(rank: rank, name: entry.habit.name, tally: entry.tally))
        .accessibilityValue(Consistency.detailSpoken(entry.tally, streak: streak))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { model.openEditForm(entry.habit.id) }
        .accessibilityAction(named: "Delete") { model.openDeleteConfirmation(entry.habit.id) }
        .accessibilityIdentifier("leaderboard-\(entry.habit.name)")
    }

    private var bar: some View {
        Capsule()
            .fill(.quaternary)
            .frame(height: 5)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: proxy.size.width * (entry.tally.share ?? 0))
                }
            }
    }
}

/// A shield beside each habit: a gold cup for a perfect record in the range, otherwise the rank
/// (customer, 2026-11-13). Every 100% habit gets the cup, so several can share it.
private struct RankShield: View {
    let rank: Int
    let perfect: Bool

    var body: some View {
        ZStack {
            PhosphorIcon("shield", size: 26)
            Group {
                if perfect {
                    PhosphorIcon("trophy-fill", size: 13)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 12, weight: .bold).monospacedDigit())
                        .minimumScaleFactor(0.7)
                        .frame(width: 15)
                }
            }
            // The shield narrows to a point, so the middle of its body sits a little above center.
            .offset(y: -1)
        }
        .foregroundStyle(perfect ? AnyShapeStyle(Color.yellow) : AnyShapeStyle(.secondary))
        .frame(width: 26, height: 26)
        .help(perfect ? "Every due day done" : "Rank \(rank)")
    }
}

/// One range tab: accent-filled when selected; hover and press come from the shared style (T-021).
private struct RangeTab: View {
    let title: String
    let spoken: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(selected ? .semibold : .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .foregroundStyle(selected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                .frame(maxWidth: .infinity, minHeight: 20)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 5).fill(Color.accentColor)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.hover(cornerRadius: 5, overLabel: true))
        .accessibilityLabel(spoken)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
