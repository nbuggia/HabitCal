import AppKit
import HabitCalKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel?
    private var statusItemController: StatusItemController?
    private var popoverController: PopoverController?
    private var dayWatcher: DayWatcher?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Another copy is already in the menu bar: keep a single icon (T-002 E.2).
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
            .filter { $0 != .current }
        guard others.isEmpty else {
            NSApp.terminate(nil)
            return
        }
        MainMenu.install()

        let options = LaunchOptions(arguments: ProcessInfo.processInfo.arguments)
        let model = AppModel(
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
