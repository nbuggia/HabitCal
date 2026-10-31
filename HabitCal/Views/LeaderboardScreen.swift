import AppKit
import HabitCalKit
import SwiftUI

/// The consistency leaderboard: habits ranked by the share of their due days done (T-016).
struct LeaderboardScreen: View {
    @Environment(AppModel.self) private var model
    @State private var listHeight: CGFloat = 0

    /// Room left for the rows, so the popover never runs off the screen (like the habit list).
    private var maxListHeight: CGFloat {
        max(120, (NSScreen.main?.visibleFrame.height ?? 800) - 200)
    }

    var body: some View {
        let entries = Consistency.board(model.habits.all, range: model.leaderboardRange, today: model.today)
        VStack(alignment: .leading, spacing: 10) {
            header
            rangePicker
            score(Consistency.overall(entries), hasHabits: !entries.isEmpty)
            if !entries.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(entries.enumerated()), id: \.element.habit.id) { index, entry in
                            LeaderboardRow(rank: index + 1, entry: entry)
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
                RangeTab(title: range.title, selected: model.leaderboardRange == range) {
                    model.pickLeaderboardRange(range)
                }
            }
        }
        .padding(2)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 7))
    }

    private func score(_ tally: ConsistencyTally, hasHabits: Bool) -> some View {
        HStack(spacing: 10) {
            Text(Consistency.percentText(tally))
                .font(.system(size: 26, weight: .bold).monospacedDigit())
            Text(caption(tally, hasHabits: hasHabits))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(hasHabits ? Consistency.scoreSpoken(tally) : "No habits yet")
        .accessibilityIdentifier("leaderboardScore")
    }

    private func caption(_ tally: ConsistencyTally, hasHabits: Bool) -> String {
        if !hasHabits { return "No habits yet." }
        return tally.due == 0 ? "No due days yet." : "of due days done across all habits"
    }
}

/// Rank, name over a bar filled to the share, and the percentage.
private struct LeaderboardRow: View {
    let rank: Int
    let entry: ConsistencyEntry

    var body: some View {
        HStack(spacing: 8) {
            Group {
                if rank == 1 && entry.tally.share != nil {
                    PhosphorIcon("trophy", size: 14).foregroundStyle(Color.yellow)
                } else {
                    Text("\(rank)").fontWeight(.bold).monospacedDigit().foregroundStyle(.secondary)
                }
            }
            .frame(width: 16)
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.habit.name).fontWeight(.semibold).lineLimit(1)
                bar
            }
            Text(Consistency.percentText(entry.tally))
                .fontWeight(.semibold)
                .monospacedDigit()
                .frame(minWidth: 38, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Consistency.rowSpoken(rank: rank, name: entry.habit.name, tally: entry.tally))
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

/// One range tab: accent-filled when selected; hover and press come from the shared style (T-021).
private struct RangeTab: View {
    let title: String
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
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
