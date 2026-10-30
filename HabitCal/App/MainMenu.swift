import AppKit

/// A main menu nobody sees. A Dock-less app has no menu bar of its own, but its key equivalents
/// still work while it's active, which it is while the popover is open. This is what makes ⌘Q quit
/// (T-002 B.19).
enum MainMenu {
    @MainActor
    static func install() {
        let appMenu = NSMenu()
        appMenu.addItem(
            withTitle: "Quit HabitCal", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let appItem = NSMenuItem()
        appItem.submenu = appMenu
        let mainMenu = NSMenu()
        mainMenu.addItem(appItem)
        NSApp.mainMenu = mainMenu
    }
}
