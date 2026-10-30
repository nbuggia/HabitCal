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

    private var popover: XCUIElement {
        app.popovers.firstMatch
    }

    private func openPopover() {
        XCTAssertTrue(statusItem.waitForExistence(timeout: 10), "status item not found")
        statusItem.click()
        XCTAssertTrue(popover.waitForExistence(timeout: 5), "popover didn't open")
    }

    private var calendarTitle: String {
        // On macOS a static text's string is its value, not its label.
        popover.staticTexts["calendarTitle"].value as? String ?? ""
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

    func testPopoverOpensOnCurrentMonthAndListAndClosesOnSecondClick() {
        launch(today: "2026-10-29")
        openPopover()
        XCTAssertEqual(calendarTitle, "October 2026")
        XCTAssertTrue(popover.staticTexts["habitsSection"].exists, "habit list not shown")
        let today = popover.descendants(matching: .any)["Thursday, October 29, 2026, today"]
        XCTAssertTrue(today.exists, "today isn't marked")
        XCTAssertTrue(popover.descendants(matching: .any)["Sunday, September 27, 2026"].exists, "neighbor days missing")

        statusItem.click()
        XCTAssertTrue(popover.waitForNonExistence(timeout: 5), "popover didn't close on a second click")
    }

    func testPagingAcrossYearAndBackToToday() {
        launch(today: "2026-10-29")
        openPopover()
        for _ in 0..<3 { popover.buttons["Next month"].click() }
        XCTAssertEqual(calendarTitle, "January 2027")
        popover.buttons["Previous month"].click()
        XCTAssertEqual(calendarTitle, "December 2026")
        popover.buttons["Today"].click()
        XCTAssertEqual(calendarTitle, "October 2026")
    }

    func testReopeningPopoverResetsToCurrentMonth() {
        launch(today: "2026-10-29")
        openPopover()
        popover.buttons["Next month"].click()
        XCTAssertEqual(calendarTitle, "November 2026")
        statusItem.click()
        XCTAssertTrue(popover.waitForNonExistence(timeout: 5))
        // Wait out the reopen guard, so the next click isn't treated as part of the close.
        Thread.sleep(forTimeInterval: 0.5)
        openPopover()
        XCTAssertEqual(calendarTitle, "October 2026")
    }

    func testEscapeFromListClosesPopover() {
        launch()
        openPopover()
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(popover.waitForNonExistence(timeout: 5), "Esc didn't close the popover")
    }

    func testCalendarColumnsFollowTheMacsWeekStart() {
        launch(today: "2026-10-29", ["-HabitCalMacFirstWeekday", "2"])
        openPopover()
        XCTAssertTrue(popover.descendants(matching: .any)["Monday, September 28, 2026"].exists)
        XCTAssertFalse(popover.descendants(matching: .any)["Sunday, September 27, 2026"].exists)
    }
}
