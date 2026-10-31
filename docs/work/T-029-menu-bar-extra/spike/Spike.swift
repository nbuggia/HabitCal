// Throwaway spike for T-029: can SwiftUI's MenuBarExtra (.window style) do what D-005 needs?
// Build with build.sh; every event is appended to the log file named in LOG below.
import AppKit
import SwiftUI

let LOG = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/mbx-spike.log"

@MainActor
final class Spike: ObservableObject {
    @Published var day = Calendar.current.component(.day, from: Date())
    @Published var opens = 0
    @Published var appears = 0
    @Published var events: [String] = []
    var escMode = "none"

    func log(_ s: String) {
        let line = "\(Date().formatted(date: .omitted, time: .standard))  \(s)"
        events.insert(line, at: 0)
        if events.count > 8 { events.removeLast() }
        if let h = FileHandle(forWritingAtPath: LOG) {
            h.seekToEndOfFile()
            h.write((line + "\n").data(using: .utf8)!)
            h.closeFile()
        } else {
            FileManager.default.createFile(atPath: LOG, contents: (line + "\n").data(using: .utf8))
        }
    }

    /// The MenuBarExtra's own window: the key window whose class name mentions MenuBarExtra.
    static func extraWindow() -> NSWindow? {
        NSApp.windows.first { String(describing: type(of: $0)).contains("MenuBarExtra") }
    }

    /// The status item's button, found in the status bar window (the MenuBarExtraAccess technique).
    static func statusButton() -> NSStatusBarButton? {
        for window in NSApp.windows where String(describing: type(of: window)).contains("NSStatusBarWindow") {
            if let button = find(in: window.contentView) { return button }
        }
        return nil
    }

    private static func find(in view: NSView?) -> NSStatusBarButton? {
        guard let view else { return nil }
        if let b = view as? NSStatusBarButton { return b }
        for sub in view.subviews { if let b = find(in: sub) { return b } }
        return nil
    }

    /// A synthetic click on the status button: mouse-up queued first, so the button's tracking loop
    /// started by the mouse-down ends.
    static func clickStatusButton() {
        guard let button = statusButton(), let window = button.window else { return }
        let point = button.convert(NSPoint(x: button.bounds.midX, y: button.bounds.midY), to: nil)
        func event(_ type: NSEvent.EventType) -> NSEvent? {
            NSEvent.mouseEvent(
                with: type, location: point, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)
        }
        guard let down = event(.leftMouseDown), let up = event(.leftMouseUp) else { return }
        NSApp.postEvent(up, atStart: false)
        window.sendEvent(down)
    }

    func closeByWindowClose() {
        log("close: window.close()  window=\(Spike.extraWindow().map { String(describing: type(of: $0)) } ?? "nil")")
        Spike.extraWindow()?.close()
    }

    func closeByStatusClick() {
        let button = Spike.statusButton()
        log("close: statusButton.performClick  button=\(button == nil ? "nil" : "found")")
        button?.performClick(nil)
    }
}

@MainActor
func visible() -> String {
    guard let w = Spike.extraWindow() else { return "no window" }
    return w.isVisible ? "OPEN" : "closed"
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var guidedOpens = 0
    var clickMonitor: Any?

    /// The customer clicks the icon; each time the window shows, the spike closes it a different way
    /// 1.5 s later. Clicks on the icon are logged, so a click that doesn't open it shows up.
    func runGuided() {
        let s = spike
        s.log("GUIDED start: click the icon, wait for it to close, repeat 5 times")
        clickMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
            if let w = event.window, String(describing: type(of: w)).contains("NSStatusBarWindow") {
                MainActor.assumeIsolated { s.log("GUIDED icon clicked  window now \(visible())") }
            }
            return event
        }
        NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification, object: nil, queue: .main
        ) { [weak self] note in
            guard let w = note.object as? NSWindow, String(describing: type(of: w)).contains("MenuBarExtra") else { return }
            MainActor.assumeIsolated {
                guard let self, w.occlusionState.contains(.visible) else { return }
                self.guidedOpens += 1
                let n = self.guidedOpens
                let methods: [(String, () -> Void)] = [
                    ("window.close()", { w.close() }),
                    ("native Esc key event", {
                        let esc = NSEvent.keyEvent(
                            with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
                            windowNumber: w.windowNumber, context: nil, characters: "\u{1b}",
                            charactersIgnoringModifiers: "\u{1b}", isARepeat: false, keyCode: 53)!
                        w.sendEvent(esc)
                    }),
                    ("orderOut", { w.orderOut(nil) }),
                    ("cancelOperation", { w.firstResponder?.tryToPerform(#selector(NSResponder.cancelOperation(_:)), with: nil) }),
                    ("window.close() again", { w.close() }),
                ]
                guard n <= methods.count else { s.log("GUIDED open #\(n): done, nothing more"); return }
                let (name, close) = methods[n - 1]
                s.log("GUIDED open #\(n): will close by \(name)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    close()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        s.log("GUIDED after \(name): window \(visible())")
                    }
                }
            }
        }
    }

    /// Scripted run of question 2: each programmatic close, then whether the next icon click opens.
    func runSelfTest() {
        let s = spike
        let steps: [(Double, String, () -> Void)] = [
            (1, "click icon (expect OPEN)", { Spike.clickStatusButton() }),
            (3, "window.close() (expect closed)", { Spike.extraWindow()?.close() }),
            (5, "click icon once (OPEN = no desync after close())", { Spike.clickStatusButton() }),
            (7, "click icon (expect closed)", { Spike.clickStatusButton() }),
            (9, "click icon (expect OPEN)", { Spike.clickStatusButton() }),
            (11, "send Esc to the window (closed = native Esc works)", {
                guard let w = Spike.extraWindow() else { return }
                let esc = NSEvent.keyEvent(
                    with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: w.windowNumber,
                    context: nil, characters: "\u{1b}", charactersIgnoringModifiers: "\u{1b}", isARepeat: false,
                    keyCode: 53)!
                w.sendEvent(esc)
            }),
            (13, "if still OPEN: close by clicking icon in code; then nothing", {
                if Spike.extraWindow()?.isVisible == true { Spike.clickStatusButton() }
            }),
            (15, "click icon once (expect OPEN)", { Spike.clickStatusButton() }),
            (17, "orderOut (expect closed)", { Spike.extraWindow()?.orderOut(nil) }),
            (19, "click icon once (OPEN = no desync after orderOut)", { Spike.clickStatusButton() }),
            (21, "click icon (expect closed); done", { Spike.clickStatusButton() }),
        ]
        s.log("SELFTEST start  statusButton=\(Spike.statusButton() == nil ? "MISSING" : "found")")
        for (t, name, action) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + t) {
                action()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { s.log("SELFTEST \(name)  ->  \(visible())") }
            }
        }
    }

    let spike = Spike()
    var monitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        spike.log("---- launched; log at \(LOG)")
        let center = NotificationCenter.default
        center.addObserver(forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main) { [spike] note in
            let name = String(describing: type(of: note.object!))
            MainActor.assumeIsolated {
                if name.contains("MenuBarExtra") { spike.opens += 1 }
                spike.log("didBecomeKey  \(name)  opens=\(spike.opens)")
            }
        }
        for (event, label) in [
            (NSWindow.didResignKeyNotification, "didResignKey"), (NSWindow.willCloseNotification, "willClose"),
        ] {
            center.addObserver(forName: event, object: nil, queue: .main) { [spike] note in
                let name = String(describing: type(of: note.object!))
                MainActor.assumeIsolated { spike.log("\(label)  \(name)") }
            }
        }
        center.addObserver(forName: NSWindow.didChangeOcclusionStateNotification, object: nil, queue: .main) {
            [spike] note in
            guard let w = note.object as? NSWindow, String(describing: type(of: w)).contains("MenuBarExtra") else { return }
            MainActor.assumeIsolated { spike.log("occlusion  visible=\(w.occlusionState.contains(.visible))") }
        }
        if CommandLine.arguments.contains("--selftest") { runSelfTest() }
        if CommandLine.arguments.contains("--guided") { runGuided() }
        // Esc: log it, then close the way the window's picker says (or not at all, to see native behavior).
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [spike] event in
            guard event.keyCode == 53 else { return event }
            let passThrough = MainActor.assumeIsolated { () -> Bool in
                spike.log("Esc pressed  mode=\(spike.escMode)")
                switch spike.escMode {
                case "window.close": spike.closeByWindowClose()
                case "statusClick": spike.closeByStatusClick()
                default: return true
                }
                return false
            }
            return passThrough ? event : nil
        }
    }
}

@main
struct SpikeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        MenuBarExtra {
            SpikeView(spike: delegate.spike)
        } label: {
            // Question 4: does the label redraw when the model changes (as at midnight)?
            SpikeLabel(spike: delegate.spike)
        }
        .menuBarExtraStyle(.window)
    }
}

/// A rough stand-in for HabitCal's icon: the day number in a rounded square, as a template image.
@MainActor
func icon(day: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
        NSBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), xRadius: 4, yRadius: 4).stroke()
        let text = "\(day)" as NSString
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 10)]
        let size = text.size(withAttributes: attrs)
        text.draw(at: NSPoint(x: (18 - size.width) / 2, y: (18 - size.height) / 2), withAttributes: attrs)
        return true
    }
    image.isTemplate = true
    return image
}

struct SpikeLabel: View {
    @ObservedObject var spike: Spike
    var body: some View { Image(nsImage: icon(day: spike.day)) }
}

struct SpikeView: View {
    @ObservedObject var spike: Spike
    @State private var escMode = "none"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MenuBarExtra spike (T-029)").font(.headline)
            Text("Opens (didBecomeKey): \(spike.opens)   onAppear: \(spike.appears)").font(.caption)
            Divider()
            Text("1. Link closes it?").font(.caption.weight(.semibold))
            Button("Open apple.com") {
                spike.log("link clicked")
                NSWorkspace.shared.open(URL(string: "https://www.apple.com")!)
            }
            Text("2. Esc closes it? Pick how, then press Esc").font(.caption.weight(.semibold))
            Picker("Esc", selection: $escMode) {
                Text("Native").tag("none")
                Text("close()").tag("window.close")
                Text("Click icon").tag("statusClick")
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: escMode) { _, mode in
                spike.escMode = mode
                spike.log("esc mode -> \(mode)")
            }
            Text("4. Icon redraws? (watch the menu bar)").font(.caption.weight(.semibold))
            Button("Advance the icon's day") {
                spike.day = spike.day % 31 + 1
                spike.log("day -> \(spike.day)")
            }
            Divider()
            ForEach(spike.events, id: \.self) { Text($0).font(.caption2.monospaced()).lineLimit(1) }
        }
        .padding(14)
        .frame(width: 300)
        .onAppear {
            spike.appears += 1
            spike.log("onAppear  appears=\(spike.appears)")
        }
    }
}
