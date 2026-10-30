import SwiftUI

/// A Phosphor icon from the asset catalog (D-008), tinted like text.
struct PhosphorIcon: View {
    let name: String
    let size: CGFloat

    init(_ name: String, size: CGFloat) {
        self.name = name
        self.size = size
    }

    var body: some View {
        Image("ph-\(name)")
            .resizable()
            .renderingMode(.template)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
