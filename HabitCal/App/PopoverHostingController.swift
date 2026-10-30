import SwiftUI

/// Hosts the popover's SwiftUI content, and routes Esc to the model.
///
/// Esc arrives here as `cancelOperation(_:)` through the responder chain whether or not a control
/// has focus. `.onKeyPress` and `.onExitCommand` only fire with focus, and buttons don't take focus
/// unless the Mac's Keyboard navigation setting is on (FM-006).
final class PopoverHostingController: NSHostingController<PopoverRoot> {
    private let model: AppModel
    var close: () -> Void = {}

    init(model: AppModel) {
        self.model = model
        super.init(rootView: PopoverRoot(model: model))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not used")
    }

    override func cancelOperation(_ sender: Any?) {
        if model.escape() == .closePopover {
            close()
        }
    }
}
