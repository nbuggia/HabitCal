import AppKit
import HabitCalKit

/// Draws the menu bar icon: a tear-off calendar page with the month cut out of a solid header bar
/// and the day number below (D-008). Geometry follows the prototype's 21 × 21 design, scaled to the
/// menu bar.
enum MenuBarIcon {
    private static let side: CGFloat = 18
    private static let design: CGFloat = 21

    static func image(for day: Day) -> NSImage {
        let image = NSImage(size: NSSize(width: side, height: side), flipped: true) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.scaleBy(x: side / design, y: side / design)
            // The cut-out uses .destinationOut. Inside a transparency layer it can only erase the icon's
            // own pixels, never the status button's highlight behind it.
            context.beginTransparencyLayer(auxiliaryInfo: nil)
            drawPage(in: context)
            drawText(abbreviation: MonthNames.abbreviation(of: day.month), day: day.day, in: context)
            context.endTransparencyLayer()
            return true
        }
        // A template image is tinted by macOS for light, dark, and tinted menu bars and Increase Contrast.
        image.isTemplate = true
        return image
    }

    private static func drawPage(in context: CGContext) {
        context.setStrokeColor(NSColor.black.cgColor)
        context.setFillColor(NSColor.black.cgColor)
        context.setLineWidth(1.5)
        context.addPath(
            CGPath(
                roundedRect: CGRect(x: 0.75, y: 0.75, width: 19.5, height: 19.5),
                cornerWidth: 4.2, cornerHeight: 4.2, transform: nil))
        context.strokePath()

        context.saveGState()
        context.addPath(
            CGPath(
                roundedRect: CGRect(x: 0, y: 0, width: design, height: design),
                cornerWidth: 4.95, cornerHeight: 4.95, transform: nil))
        context.clip()
        context.fill(CGRect(x: 0, y: 0, width: design, height: 9.6))
        context.restoreGState()
    }

    private static func drawText(abbreviation: String, day: Int, in context: CGContext) {
        context.setBlendMode(.destinationOut)
        draw(abbreviation, font: .systemFont(ofSize: 5.2, weight: .heavy), kern: 0.3, baseline: 6.7)
        context.setBlendMode(.normal)
        draw(String(day), font: .monospacedDigitSystemFont(ofSize: 8.4, weight: .bold), kern: 0, baseline: 17.6)
    }

    /// Draws `text` centred horizontally on the page, with its baseline at `baseline` (flipped coordinates).
    private static func draw(_ text: String, font: NSFont, kern: CGFloat, baseline: CGFloat) {
        let string = NSAttributedString(
            string: text,
            attributes: [
                .font: font, .kern: kern, .foregroundColor: NSColor.black,
            ])
        let width = string.size().width - kern
        string.draw(at: NSPoint(x: (design - width) / 2, y: baseline - font.ascender))
    }
}
