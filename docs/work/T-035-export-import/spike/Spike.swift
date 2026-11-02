// Throwaway T-035 spike: in a sandboxed, Dock-less (LSUIElement) app, does an NSSavePanel run after
// NSApp.activate come to the front? Writes its result to the file named in argv[1] (inside the
// container), and quits after a few seconds without anyone clicking.
import AppKit

final class Delegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NSApp.activate()
            let panel = NSSavePanel()
            panel.nameFieldStringValue = "HabitCal Habits 2026-11-01.json"
            panel.level = .modalPanel
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                NSApp.abortModal()
            }
            let result = panel.runModal()
            print("SPIKE runModal returned \(result.rawValue)")
            NSApp.terminate(nil)
        }
    }
}

let app = NSApplication.shared
let delegate = Delegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
