import AppKit
import UniformTypeIdentifiers

/// The only code that shows file dialogs and alerts (T-035). Each one brings HabitCal forward first:
/// it has no Dock icon, so a dialog behind another app's window couldn't be reached (E.8). Callers
/// open them only after the panel has closed (`AppModel.closePopoverThen`), since the panel sits above
/// modal panels.
@MainActor
final class FileDialogs {
    /// Debug-only answers for UI tests, which can't drive the system's out-of-process panels: a file
    /// name inside the test data folder, or nil for Cancel (TESTING.md, FM-007).
    struct TestAnswers {
        var exportTo: String?
        /// A file in the test data folder to import, or `cancel`.
        var importFrom: String?
        /// The confirmation's answer: true for Replace.
        var confirm: Bool?
        var folder: URL
    }

    private let testAnswers: TestAnswers?
    /// Debug answers only: where an error's title goes instead of an alert, for UI tests to read.
    var onTestError: (String) -> Void = { _ in }

    init(testAnswers: TestAnswers?) {
        self.testAnswers = testAnswers
    }

    /// The save dialog, suggesting `name`. Nil if cancelled (E.1). It asks before replacing a file (E.9).
    func chooseExportURL(name: String) -> URL? {
        if let testAnswers, let exportTo = testAnswers.exportTo {
            return exportTo == "cancel" ? nil : testAnswers.folder.appendingPathComponent(exportTo)
        }
        NSApp.activate()
        let panel = NSSavePanel()
        panel.nameFieldStringValue = name
        panel.allowedContentTypes = [.json]
        panel.level = .modalPanel
        return panel.runModal() == .OK ? panel.url : nil
    }

    /// The open dialog, for JSON files. Nil if cancelled (E.1).
    func chooseImportURL() -> URL? {
        if let testAnswers, let importFrom = testAnswers.importFrom {
            return importFrom == "cancel" ? nil : testAnswers.folder.appendingPathComponent(importFrom)
        }
        NSApp.activate()
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.level = .modalPanel
        return panel.runModal() == .OK ? panel.url : nil
    }

    /// Replace or Cancel. Cancel is the default button, so Return doesn't replace (T-035 §5).
    func confirmReplace(title: String, message: String) -> Bool {
        if let testAnswers { return testAnswers.confirm ?? false }
        NSApp.activate()
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = message
        let replace = alert.addButton(withTitle: "Replace")
        replace.hasDestructiveAction = true
        replace.keyEquivalent = ""
        let cancel = alert.addButton(withTitle: "Cancel")
        cancel.keyEquivalent = "\r"
        alert.window.level = .modalPanel
        return alert.runModal() == .alertFirstButtonReturn
    }

    /// An alert with the reason macOS gave (E.2, E.3, E.4, E.5).
    func showError(title: String, reason: String) {
        guard testAnswers == nil else {
            onTestError(title)
            return
        }
        NSApp.activate()
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = reason
        alert.window.level = .modalPanel
        alert.runModal()
    }
}
