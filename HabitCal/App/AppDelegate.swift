import AppKit
import HabitCalKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel?
    private var statusItemController: StatusItemController?
    private var popoverController: PopoverController?
    private var dayWatcher: DayWatcher?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let options = LaunchOptions(arguments: ProcessInfo.processInfo.arguments)
        let model = AppModel(
            today: options.todaySource.today(in: .autoupdatingCurrent),
            macWeekStart: WeekStart.fromMac(firstWeekday: options.macFirstWeekday()))
        self.model = model

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
