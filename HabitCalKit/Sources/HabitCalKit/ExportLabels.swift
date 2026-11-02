import Foundation

extension HabitLabels {
    /// The save dialog's suggested name (T-035 B.2).
    public static func exportFileName(today: Day) -> String {
        "HabitCal Habits \(today.iso).json"
    }
}
