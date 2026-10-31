import AppKit
import HabitCalKit

/// Builds the model and its watchers. SwiftUI builds the menu bar extra's scene before
/// `applicationDidFinishLaunching`, so they're built in `init` (T-029).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static func launchedBefore(_ a: NSRunningApplication, _ b: NSRunningApplication) -> Bool {
        let aDate = a.launchDate ?? .distantPast
        let bDate = b.launchDate ?? .distantPast
        return aDate == bDate ? a.processIdentifier < b.processIdentifier : aDate < bDate
    }

    /// Another copy is already in the menu bar: keep a single icon (T-002 E.2). Only the later of
    /// two copies exits, so two started at the same moment don't both quit. It runs before anything
    /// is built, so the exiting copy never writes a seed or shows an icon.
    private static func exitIfAnotherCopyIsRunning() {
        let current = NSRunningApplication.current
        let earlier = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
            .filter { $0 != current && launchedBefore($0, current) }
        if !earlier.isEmpty { exit(0) }
    }

    let model: AppModel
    let panel: PanelController
    private let dayWatcher: DayWatcher

    override init() {
        Self.exitIfAnotherCopyIsRunning()
        let options = LaunchOptions(arguments: ProcessInfo.processInfo.arguments)
        let store = HabitStore(directory: options.dataDirectory)
        if let seed = options.seedData {
            try? FileManager.default.createDirectory(at: options.dataDirectory, withIntermediateDirectories: true)
            try? seed.write(to: store.fileURL)
        }
        let model = AppModel(
            store: store,
            today: options.todaySource.today(in: .autoupdatingCurrent),
            macWeekStart: WeekStart.fromMac(firstWeekday: options.macFirstWeekday()),
            defaults: options.defaults,
            loginItem: LoginItem())
        self.model = model
        panel = PanelController(model: model)
        dayWatcher = DayWatcher(source: options.todaySource, macFirstWeekday: options.macFirstWeekday, model: model)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        MainMenu.install()
        model.applyFirstLaunchLoginItemDefault()
    }
}
