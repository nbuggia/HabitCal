import Foundation

extension HabitLabels {
    /// The save dialog's suggested name (T-035 B.2).
    public static func exportFileName(today: Day) -> String {
        "HabitCal Habits \(today.iso).json"
    }
}

/// The import confirmation's text (T-035 spec, section 5).
public struct ImportConfirmationLabel: Equatable, Sendable {
    public let title: String
    public let message: String
}

extension HabitLabels {
    /// "Your 5 habits (last checked off Oct 31) will be replaced by the 6 habits in “file”
    /// (last checked off Mar 2). This can't be undone." With sync on, "on all your Macs" (T-039 B.14).
    public static func importConfirmation(
        current: Habits, incoming: Habits, fileName: String, syncOn: Bool, today: Day
    ) -> ImportConfirmationLabel {
        let mine = count(current.all.count) + (syncOn ? " on all your Macs" : "")
        let message =
            "Your \(mine) (\(lastCheckOff(current, today: today))) will be replaced by the "
            + "\(count(incoming.all.count)) in “\(fileName)” (\(lastCheckOff(incoming, today: today))). "
            + "This can't be undone."
        return ImportConfirmationLabel(title: "Replace your habits?", message: message)
    }

    /// "last checked off Oct 31", with the year when it isn't this year, or "no check-offs". Only shown
    /// habits and done checks count: v2 keeps unchecks and deleted habits.
    public static func lastCheckOff(_ habits: Habits, today: Day) -> String {
        guard let latest = habits.all.flatMap(\.checkOffs).max() else { return "no check-offs" }
        let date = "\(MonthNames.abbreviation(of: latest.month).capitalized) \(latest.day)"
        return "last checked off " + (latest.year == today.year ? date : "\(date), \(latest.year)")
    }

    private static func count(_ n: Int) -> String {
        n == 1 ? "1 habit" : "\(n) habits"
    }
}
