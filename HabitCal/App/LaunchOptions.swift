import Foundation
import HabitCalKit

/// Debug-only launch arguments that let UI tests run against a fixed date and isolated settings (FM-007).
/// Release builds ignore every argument.
struct LaunchOptions {
    /// The UserDefaults to use: a named suite under `-HabitCalDefaultsSuite`, otherwise the standard one.
    let defaults: UserDefaults
    /// Where "today" comes from: a fixed day under `-HabitCalToday YYYY-MM-DD`, otherwise the Mac's clock.
    let todaySource: any TodaySource
    /// The Mac's first weekday (1 = Sunday): a fixed value under `-HabitCalMacFirstWeekday N`,
    /// otherwise the Mac's current setting, read each time.
    let macFirstWeekday: @Sendable () -> Int
    /// The folder holding habits.json: Application Support/HabitCal in the app's container, or under
    /// `-HabitCalDataDir name`, Application Support/HabitCal-tests/name. It's a folder name, not a
    /// path, because the sandboxed app can't reach the test runner's folders.
    let dataDirectory: URL
    /// Under `-HabitCalSeedData base64`, the exact bytes to write to habits.json before loading.
    let seedData: Data?

    init(arguments: [String]) {
        var defaults = UserDefaults.standard
        var todaySource: any TodaySource = SystemTodaySource()
        var macFirstWeekday: @Sendable () -> Int = { Calendar.autoupdatingCurrent.firstWeekday }
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        var dataDirectory = applicationSupport.appendingPathComponent("HabitCal", isDirectory: true)
        var seedData: Data?
        #if DEBUG
            if let suite = Self.value(after: "-HabitCalDefaultsSuite", in: arguments),
                let suiteDefaults = UserDefaults(suiteName: suite)
            {
                defaults = suiteDefaults
            }
            if let iso = Self.value(after: "-HabitCalToday", in: arguments), let day = Day(iso: iso) {
                todaySource = FixedTodaySource(day)
            }
            if let value = Self.value(after: "-HabitCalMacFirstWeekday", in: arguments), let weekday = Int(value) {
                macFirstWeekday = { weekday }
            }
            if let folder = Self.value(after: "-HabitCalDataDir", in: arguments) {
                dataDirectory = applicationSupport.appendingPathComponent("HabitCal-tests", isDirectory: true)
                    .appendingPathComponent(folder, isDirectory: true)
            }
            if let base64 = Self.value(after: "-HabitCalSeedData", in: arguments) {
                seedData = Data(base64Encoded: base64)
            }
        #endif
        self.defaults = defaults
        self.todaySource = todaySource
        self.macFirstWeekday = macFirstWeekday
        self.dataDirectory = dataDirectory
        self.seedData = seedData
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }
}
