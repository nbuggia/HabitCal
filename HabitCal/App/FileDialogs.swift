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
        var folder: URL
    }

    private let testAnswers: TestAnswers?

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

    /// An alert with the reason macOS gave (E.2, E.3, E.4, E.5).
    func showError(title: String, reason: String) {
        guard testAnswers == nil else { return }
        NSApp.activate()
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = reason
        alert.window.level = .modalPanel
        alert.runModal()
    }
}
