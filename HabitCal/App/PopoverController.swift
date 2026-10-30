import AppKit

/// Opens and closes the popover under the status item.
@MainActor
final class PopoverController: NSObject, NSPopoverDelegate {
    /// A click on the status item while a `.transient` popover is open closes the popover on
    /// mouse-down, before the button's action runs. Without this window the action would reopen it.
    private static let reopenGuard: TimeInterval = 0.3

    private let popover = NSPopover()
    private let hostingController = PopoverHostingController(rootView: PopoverRoot())
    private var lastClosedUptime: TimeInterval = 0

    override init() {
        super.init()
        popover.behavior = .transient
        popover.animates = false
        popover.contentViewController = hostingController
        popover.delegate = self
    }

    func toggle(relativeTo button: NSView) {
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        guard ProcessInfo.processInfo.systemUptime - lastClosedUptime > Self.reopenGuard else { return }
        // A Dock-less app must activate itself, or the popover never becomes key (FM-006).
        NSApp.activate()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        hostingController.view.window?.makeFirstResponder(hostingController.view)
    }

    func popoverDidClose(_ notification: Notification) {
        lastClosedUptime = ProcessInfo.processInfo.systemUptime
    }
}
