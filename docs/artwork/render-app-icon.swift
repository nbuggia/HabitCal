import AppKit

/// Draws the app icon at `px` pixels: a macOS-style rounded square holding a tear-off calendar page
/// with a green header and a check mark.
func icon(_ px: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(px) / 1024
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.scaleBy(x: s, y: s)
    // Background tile (Apple's grid: 824 pt tile centred in 1024 with ~185 pt corner radius).
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: NSColor.black.withAlphaComponent(0.25).cgColor)
    ctx.addPath(tilePath); ctx.setFillColor(NSColor.white.cgColor); ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addPath(tilePath); ctx.clip()
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [NSColor(white: 1, alpha: 1).cgColor, NSColor(white: 0.93, alpha: 1).cgColor] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 924), end: CGPoint(x: 0, y: 100), options: [])
    // Green header bar (top of tile; CG origin is bottom-left).
    let green = NSColor(srgbRed: 0.20, green: 0.74, blue: 0.40, alpha: 1)
    ctx.setFillColor(green.cgColor)
    ctx.fill(CGRect(x: 100, y: 924 - 250, width: 824, height: 250))
    ctx.restoreGState()
    // Binder rings.
    for x in [330.0, 694.0] {
        ctx.setFillColor(NSColor(white: 0.95, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(x: x - 34, y: 924 - 70 - 34, width: 68, height: 68))
        ctx.setFillColor(NSColor(srgbRed: 0.12, green: 0.50, blue: 0.27, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(x: x - 18, y: 924 - 70 - 18, width: 36, height: 36))
    }
    // Check mark.
    let check = CGMutablePath()
    check.move(to: CGPoint(x: 330, y: 430))
    check.addLine(to: CGPoint(x: 460, y: 300))
    check.addLine(to: CGPoint(x: 700, y: 560))
    ctx.addPath(check)
    ctx.setStrokeColor(green.cgColor)
    ctx.setLineWidth(86); ctx.setLineCap(.round); ctx.setLineJoin(.round)
    ctx.strokePath()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let out = CommandLine.arguments[1]
for px in Set([16, 32, 64, 128, 256, 512, 1024]) {
    try! icon(px).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/icon_\(px).png"))
}
