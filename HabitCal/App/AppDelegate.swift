import AppKit
import HabitCalKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static func launchedBefore(_ a: NSRunningApplication, _ b: NSRunningApplication) -> Bool {
        let aDate = a.launchDate ?? .distantPast
        let bDate = b.launchDate ?? .distantPast
        return aDate == bDate ? a.processIdentifier < b.processIdentifier : aDate < bDate
    }

    private var model: AppModel?
    private var statusItemController: StatusItemController?
    private var popoverController: PopoverController?
    private var dayWatcher: DayWatcher?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Another copy is already in the menu bar: keep a single icon (T-002 E.2). Only the later of
        // two copies exits, so two started at the same moment don't both quit.
        let current = NSRunningApplication.current
        let earlier = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
            .filter { $0 != current && Self.launchedBefore($0, current) }
        guard earlier.isEmpty else {
            NSApp.terminate(nil)
            return
        }
        MainMenu.install()

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
        model.applyFirstLaunchLoginItemDefault()

        let popoverController = PopoverController(model: model)
        self.popoverController = popoverController
        let statusItemController = StatusItemController { button in
            popoverController.toggle(relativeTo: button)
        }
        statusItemController.show(model.today)
        self.statusItemController = statusItemController

        dayWatcher = DayWatcher(
            source: options.todaySource, macFirstWeekday: options.macFirstWeekday, model: model
        ) { today in
            statusItemController.show(today)
        }
    }
}
