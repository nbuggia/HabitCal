import SwiftUI

/// The popover's button style: a soft rounded highlight on hover and a darker one while pressed, so
/// every click feels answered (T-021). Disabled buttons dim and don't highlight.
struct HoverButtonStyle: ButtonStyle {
    /// Corner radius of the highlight; half the button's size makes it a circle.
    var cornerRadius: CGFloat = 5
    /// How far the highlight reaches past the label, so text buttons don't sit flush in it.
    var outset: CGFloat = 0
    /// Draw the highlight over the label, for buttons whose label has its own fill.
    var overLabel = false

    func makeBody(configuration: Configuration) -> some View {
        HoverButtonBody(configuration: configuration, style: self)
    }
}

private struct HoverButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let style: HoverButtonStyle
    @Environment(\.isEnabled) private var isEnabled
    /// Keyboard focus (with the Mac's Keyboard navigation on) shows the hover highlight, since the
    /// custom style draws no focus ring.
    @Environment(\.isFocused) private var isFocused
    @State private var hovering = false

    var body: some View {
        configuration.label
            .background {
                if !style.overLabel { highlight }
            }
            .overlay {
                if style.overLabel { highlight }
            }
            .opacity(isEnabled ? 1 : 0.4)
            .onHover { hovering = $0 }
    }

    private var highlight: some View {
        RoundedRectangle(cornerRadius: style.cornerRadius)
            .fill(Color.primary.opacity(amount))
            .padding(-style.outset)
            .allowsHitTesting(false)
    }

    private var amount: Double {
        guard isEnabled else { return 0 }
        if configuration.isPressed { return 0.16 }
        return hovering || isFocused ? 0.08 : 0
    }
}

extension ButtonStyle where Self == HoverButtonStyle {
    /// Icon and text buttons.
    static var hover: HoverButtonStyle { HoverButtonStyle() }

    static func hover(cornerRadius: CGFloat = 5, outset: CGFloat = 0, overLabel: Bool = false) -> HoverButtonStyle {
        HoverButtonStyle(cornerRadius: cornerRadius, outset: outset, overLabel: overLabel)
    }
}
