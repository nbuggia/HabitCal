import AppKit

/// Opens and closes the popover under the status item.
@MainActor
final class PopoverController: NSObject, NSPopoverDelegate {
    /// A click on the status item while a `.transient` popover is open closes the popover on
    /// mouse-down, before the button's action runs. Without this window the action would reopen it.
    private static let reopenGuard: TimeInterval = 0.3

    private let model: AppModel
    private let popover = NSPopover()
    private let hostingController: PopoverHostingController
    private var lastClosedUptime: TimeInterval = 0

    init(model: AppModel) {
        self.model = model
        hostingController = PopoverHostingController(model: model)
        super.init()
        popover.behavior = .transient
        popover.animates = false
        popover.contentViewController = hostingController
        popover.delegate = self
        hostingController.close = { [weak self] in self?.close() }
        model.closePopover = { [weak self] in self?.close() }
        model.screenDidChange = { [weak self] in self?.focusHostingView() }
    }

    func toggle(relativeTo button: NSView) {
        if popover.isShown {
            close()
            return
        }
        guard ProcessInfo.processInfo.systemUptime - lastClosedUptime > Self.reopenGuard else { return }
        model.resetForOpen()
        // A Dock-less app must activate itself, or the popover never becomes key (FM-006).
        NSApp.activate()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        // Esc starts its trip up the responder chain here, so it reaches PopoverHostingController.
        focusHostingView()
    }

    /// Puts the responder chain's start back on the hosting view. A focused button that a screen
    /// change removes can leave the window as first responder, outside the chain that handles Esc.
    func focusHostingView() {
        hostingController.view.window?.makeFirstResponder(hostingController.view)
    }

    func close() {
        popover.performClose(nil)
    }

    func popoverDidClose(_ notification: Notification) {
        lastClosedUptime = ProcessInfo.processInfo.systemUptime
    }
}
