import AppKit
import SwiftUI

/// Reports the window the popover's content is in, each time it moves into one. A MenuBarExtra
/// doesn't expose its window, and matching windows by class name would depend on a private class.
struct PanelWindowHook: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> HookView {
        HookView(onWindow: onWindow)
    }

    func updateNSView(_ view: HookView, context: Context) {}

    final class HookView: NSView {
        private let onWindow: (NSWindow) -> Void

        init(onWindow: @escaping (NSWindow) -> Void) {
            self.onWindow = onWindow
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("not used")
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window { onWindow(window) }
        }
    }
}
