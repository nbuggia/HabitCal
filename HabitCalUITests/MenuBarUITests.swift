import XCTest

/// Menu bar: the status item and the popover it opens.
@MainActor
final class MenuBarUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-HabitCalDefaultsSuite", "uitest-\(UUID().uuidString)"]
        app.launch()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testStatusItemOpensAndClosesPopover() {
        let statusItem = app.statusItems["HabitCalStatusItem"]
        XCTAssertTrue(statusItem.waitForExistence(timeout: 10), "status item not found")

        statusItem.click()
        let popover = app.popovers.firstMatch
        XCTAssertTrue(popover.waitForExistence(timeout: 5), "popover didn't open")

        statusItem.click()
        XCTAssertTrue(popover.waitForNonExistence(timeout: 5), "popover didn't close on a second click")
    }
}
