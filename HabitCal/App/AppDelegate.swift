import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private var popoverController: PopoverController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let options = LaunchOptions(arguments: ProcessInfo.processInfo.arguments)
        _ = options.defaults

        let popoverController = PopoverController()
        self.popoverController = popoverController
        statusItemController = StatusItemController { button in
            popoverController.toggle(relativeTo: button)
        }
    }
}
