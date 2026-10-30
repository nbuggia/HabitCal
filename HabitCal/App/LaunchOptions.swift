import Foundation

/// Debug-only launch arguments that let UI tests run against isolated settings (FM-007).
/// Release builds ignore every argument.
struct LaunchOptions {
    /// The UserDefaults to use: a named suite under `-HabitCalDefaultsSuite`, otherwise the standard one.
    let defaults: UserDefaults

    init(arguments: [String]) {
        #if DEBUG
            if let suite = Self.value(after: "-HabitCalDefaultsSuite", in: arguments),
                let suiteDefaults = UserDefaults(suiteName: suite)
            {
                defaults = suiteDefaults
                return
            }
        #endif
        defaults = .standard
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }
}
