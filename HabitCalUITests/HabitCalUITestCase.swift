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

    /// The app's only status item. An identifier set on a MenuBarExtra's label may not reach it (T-029).
    var statusItem: XCUIElement {
        app.statusItems.firstMatch
    }

    /// The MenuBarExtra panel, found by the identifier on `PopoverRoot` (T-029, D-009).
    var popover: XCUIElement {
        app.descendants(matching: .any).matching(identifier: "habitcalPanel").firstMatch
    }

    func openPopover() {
        XCTAssertTrue(statusItem.waitForExistence(timeout: 10), "status item not found")
        statusItem.click()
        XCTAssertTrue(popover.waitForExistence(timeout: 5), "popover didn't open")
    }

    /// Selects Sunday, October 25 in the calendar, a day Run is due. On the tests' Thursday Run isn't
    /// due, so it isn't listed (T-036).
    func showRunsSunday() {
        element("Sunday, October 25, 2026").click()
        XCTAssertTrue(element("Edit Run").waitForExistence(timeout: 5), "Run isn't listed on its Sunday")
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
