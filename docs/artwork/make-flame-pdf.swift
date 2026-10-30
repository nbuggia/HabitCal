import AppKit

// Converts docs/artwork/flame.svg (the source) to the vector PDF the app ships in its asset
// catalog. Asset catalogs don't render SVG gradients reliably; PDF gradients they do.
// Run from the repo root: swiftc -o /tmp/make-flame-pdf docs/artwork/make-flame-pdf.swift && /tmp/make-flame-pdf
let svg = NSImage(contentsOf: URL(fileURLWithPath: "docs/artwork/flame.svg"))!
var box = CGRect(x: 0, y: 0, width: 256, height: 256)
let out = URL(fileURLWithPath: "HabitCal/Assets.xcassets/flame.imageset/flame.pdf") as CFURL
let pdf = CGContext(out, mediaBox: &box, nil)!
pdf.beginPDFPage(nil)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: pdf, flipped: false)
svg.draw(in: box)
NSGraphicsContext.restoreGraphicsState()
pdf.endPDFPage()
pdf.closePDF()
