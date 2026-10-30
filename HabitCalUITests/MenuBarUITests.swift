import XCTest

/// Menu bar: the status item and the popover it opens.
@MainActor
final class MenuBarUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
    }

    override func tearDown() async throws {
        app?.terminate()
    }

    /// Launches with a fixed today and fresh settings, so tests never depend on the real date (FM-007).
    private func launch(today: String = "2026-10-29", _ extra: [String] = []) {
        app = XCUIApplication()
        app.launchArguments =
            ["-HabitCalToday", today, "-HabitCalDefaultsSuite", "uitest-\(UUID().uuidString)"] + extra
        app.launch()
    }

    private var statusItem: XCUIElement {
        app.statusItems["HabitCalStatusItem"]
    }

    func testStatusItemOpensAndClosesPopover() {
        launch()
        XCTAssertTrue(statusItem.waitForExistence(timeout: 10), "status item not found")

        statusItem.click()
        let popover = app.popovers.firstMatch
        XCTAssertTrue(popover.waitForExistence(timeout: 5), "popover didn't open")

        statusItem.click()
        XCTAssertTrue(popover.waitForNonExistence(timeout: 5), "popover didn't close on a second click")
    }

    func testMenuBarIconShowsTodaysDate() {
        launch(today: "2026-10-29")
        XCTAssertTrue(statusItem.waitForExistence(timeout: 10))
        XCTAssertEqual(statusItem.label, "HabitCal, Thursday, October 29")
    }
}
