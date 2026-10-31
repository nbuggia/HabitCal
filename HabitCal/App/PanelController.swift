import AppKit

/// What the MenuBarExtra (D-009) doesn't do on its own: reset the popover on every open, close it
/// from code, close it when another app activates, and handle Esc one level at a time (T-029).
@MainActor
final class PanelController {
    private let model: AppModel
    private weak var window: NSWindow?
    private var windowObserver: NSObjectProtocol?
    private var resignObserver: NSObjectProtocol?
    private var keyMonitor: Any?
    /// True until the first reset, and again after each real close. A display wake also makes the
    /// window visible again, but it was never closed, so a half-typed form survives it.
    private var closedSinceReset = true

    init(model: AppModel) {
        self.model = model
        model.closePopover = { [weak self] in self?.close() }
        // A MenuBarExtra only resigns key when another app activates (the T-029 spike), so switching
        // apps and opening the website link would leave it open.
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.close() }
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let passThrough = MainActor.assumeIsolated { self?.handleKeyDown(event) ?? true }
            return passThrough ? event : nil
        }
    }

    /// Called by `PanelWindowHook` each time the popover's content moves into a window.
    func attach(_ window: NSWindow) {
        if window !== self.window {
            if let windowObserver { NotificationCenter.default.removeObserver(windowObserver) }
            self.window = window
            windowObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didChangeOcclusionStateNotification, object: window, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.occlusionChanged() }
            }
        }
        // On the first open the hook can arrive after the first "visible" notification.
        if window.isVisible { resetIfReopened() }
    }

    /// Closes the panel the way Esc does. `close()` and `orderOut` would leave the icon highlighted
    /// and swallow the next click (the T-029 spike).
    func close() {
        guard let window, window.isVisible else { return }
        window.firstResponder?.tryToPerform(#selector(NSResponder.cancelOperation(_:)), with: nil)
    }

    private func occlusionChanged() {
        guard let window else { return }
        if window.occlusionState.contains(.visible) {
            resetIfReopened()
        } else if !window.isVisible {
            closedSinceReset = true
        }
    }

    private func resetIfReopened() {
        guard closedSinceReset else { return }
        closedSinceReset = false
        model.resetForOpen()
    }

    /// Esc backs out one level (`AppModel.escape()`); from the list it passes on, and the MenuBarExtra
    /// closes itself. Returns whether the event should continue.
    private func handleKeyDown(_ event: NSEvent) -> Bool {
        guard event.keyCode == 53, let window, event.window === window else { return true }
        // An input method composing text uses Esc to cancel the composition.
        if let editor = window.firstResponder as? NSTextView, editor.hasMarkedText() { return true }
        return model.escape() == .closePopover
    }
}
