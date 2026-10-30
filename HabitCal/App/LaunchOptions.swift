import Foundation
import HabitCalKit

/// Debug-only launch arguments that let UI tests run against a fixed date and isolated settings (FM-007).
/// Release builds ignore every argument.
struct LaunchOptions {
    /// The UserDefaults to use: a named suite under `-HabitCalDefaultsSuite`, otherwise the standard one.
    let defaults: UserDefaults
    /// Where "today" comes from: a fixed day under `-HabitCalToday YYYY-MM-DD`, otherwise the Mac's clock.
    let todaySource: any TodaySource

    init(arguments: [String]) {
        var defaults = UserDefaults.standard
        var todaySource: any TodaySource = SystemTodaySource()
        #if DEBUG
            if let suite = Self.value(after: "-HabitCalDefaultsSuite", in: arguments),
                let suiteDefaults = UserDefaults(suiteName: suite)
            {
                defaults = suiteDefaults
            }
            if let iso = Self.value(after: "-HabitCalToday", in: arguments), let day = Day(iso: iso) {
                todaySource = FixedTodaySource(day)
            }
        #endif
        self.defaults = defaults
        self.todaySource = todaySource
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }
}
