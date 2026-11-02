// Lists the frontmost on-screen windows (owner, layer), front to back.
import CoreGraphics
import Foundation
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
for w in list.prefix(12) {
    let owner = w[kCGWindowOwnerName as String] as? String ?? "?"
    let layer = w[kCGWindowLayer as String] as? Int ?? -1
    let b = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
    print("layer \(layer)  \(owner)  \(b["Width"] ?? 0)x\(b["Height"] ?? 0)")
}
