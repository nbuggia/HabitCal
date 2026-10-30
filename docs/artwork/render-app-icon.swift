import AppKit

enum Glyph { case check, fire }

/// The app's streak color and the calendar-page green.
let flame = NSColor(srgbRed: 1.00, green: 0.48, blue: 0.10, alpha: 1)
let leaf = NSColor(srgbRed: 0.20, green: 0.74, blue: 0.40, alpha: 1)
/// The Phosphor "fire" icon (regular weight, MIT), the same one the app shows beside streaks.
let fireSVG = """
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256"><path fill="#000000" d="M143.38,17.85a8,8,0,0,0-12.63,3.41l-22,60.41L84.59,58.26a8,8,0,0,0-11.93.89C51,87.53,40,116.08,40,144a88,88,0,0,0,176,0C216,84.55,165.21,36,143.38,17.85Zm40.51,135.49a57.6,57.6,0,0,1-46.56,46.55A7.65,7.65,0,0,1,136,200a8,8,0,0,1-1.32-15.89c16.57-2.79,30.63-16.85,33.44-33.45a8,8,0,0,1,15.78,2.68Z"/></svg>
"""

/// Draws the app icon at `px` pixels: a macOS-style rounded square holding a tear-off calendar page
/// with a colored header and a glyph.
func icon(_ px: Int, header: NSColor, ringShadow: NSColor, glyph: Glyph, glyphColor: NSColor) -> NSBitmapImageRep {
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
    // Header bar (top of tile; CG origin is bottom-left).
    ctx.setFillColor(header.cgColor)
    ctx.fill(CGRect(x: 100, y: 924 - 250, width: 824, height: 250))
    ctx.restoreGState()
    // Binder rings.
    for x in [330.0, 694.0] {
        ctx.setFillColor(NSColor(white: 0.95, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(x: x - 34, y: 924 - 70 - 34, width: 68, height: 68))
        ctx.setFillColor(ringShadow.cgColor)
        ctx.fillEllipse(in: CGRect(x: x - 18, y: 924 - 70 - 18, width: 36, height: 36))
    }
    switch glyph {
    case .check:
        let check = CGMutablePath()
        check.move(to: CGPoint(x: 330, y: 430))
        check.addLine(to: CGPoint(x: 460, y: 300))
        check.addLine(to: CGPoint(x: 700, y: 560))
        ctx.addPath(check)
        ctx.setStrokeColor(glyphColor.cgColor)
        ctx.setLineWidth(86); ctx.setLineCap(.round); ctx.setLineJoin(.round)
        ctx.strokePath()
    case .fire:
        // Tint the SVG: draw it, then fill over it with source-atop.
        let svg = NSImage(data: Data(fireSVG.utf8))!
        let size: CGFloat = 470
        let rect = NSRect(x: 512 - size / 2, y: 140, width: size, height: size)
        let tinted = NSImage(size: rect.size, flipped: false) { r in
            svg.draw(in: r)
            glyphColor.set()
            r.fill(using: .sourceAtop)
            return true
        }
        tinted.draw(in: rect)
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let out = CommandLine.arguments[1]
let darkLeaf = NSColor(srgbRed: 0.12, green: 0.50, blue: 0.27, alpha: 1)
let darkFlame = NSColor(srgbRed: 0.70, green: 0.30, blue: 0.04, alpha: 1)
let variants: [(String, NSColor, NSColor, Glyph, NSColor)] = [
    ("check", leaf, darkLeaf, .check, leaf),
    ("fire-green", leaf, darkLeaf, .fire, flame),
    ("fire-orange", flame, darkFlame, .fire, flame),
    ("fire-black", NSColor(white: 0.11, alpha: 1), NSColor(white: 0.30, alpha: 1), .fire, flame),
]
for (name, header, ring, glyph, color) in variants {
    for px in [32, 128, 512, 1024] {
        let rep = icon(px, header: header, ringShadow: ring, glyph: glyph, glyphColor: color)
        try! rep.representation(using: .png, properties: [:])!.write(
            to: URL(fileURLWithPath: "\(out)/app-icon-\(name)-\(px).png"))
    }
}
