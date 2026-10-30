import XCTest

/// Shared launch and lookup helpers. Every launch uses a fixed today, a fresh settings suite, and a
/// fresh data folder inside the app's container, so tests never touch real data (FM-007).
@MainActor
class HabitCalUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
    }

    override func tearDown() async throws {
        app?.terminate()
    }

    /// - Parameters:
    ///   - dataFolder: reuse one to test persistence across a relaunch.
    ///   - seed: the exact contents to write to habits.json before loading.
    func launch(
        today: String = "2026-10-29", suite: String = "uitest-\(UUID().uuidString)",
        dataFolder: String = "uitest-\(UUID().uuidString)", seed: String? = nil, _ extra: [String] = []
    ) {
        app = XCUIApplication()
        var arguments = ["-HabitCalToday", today, "-HabitCalDefaultsSuite", suite, "-HabitCalDataDir", dataFolder]
        if let seed {
            arguments += ["-HabitCalSeedData", Data(seed.utf8).base64EncodedString()]
        }
        app.launchArguments = arguments + extra
        app.launch()
    }

    var statusItem: XCUIElement {
        app.statusItems["HabitCalStatusItem"]
    }

    var popover: XCUIElement {
        app.popovers.firstMatch
    }

    func openPopover() {
        XCTAssertTrue(statusItem.waitForExistence(timeout: 10), "status item not found")
        statusItem.click()
        XCTAssertTrue(popover.waitForExistence(timeout: 5), "popover didn't open")
    }

    /// Any element in the popover with this accessibility label.
    func element(_ label: String) -> XCUIElement {
        popover.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    /// A static text by its string. On macOS a `Text`'s string is its value, not its label.
    func text(_ string: String) -> XCUIElement {
        popover.staticTexts.matching(NSPredicate(format: "value == %@", string)).firstMatch
    }

    var calendarTitle: String {
        popover.staticTexts["calendarTitle"].value as? String ?? ""
    }
}
