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
    private func launch(
        today: String = "2026-10-29", suite: String = "uitest-\(UUID().uuidString)", _ extra: [String] = []
    ) {
        app = XCUIApplication()
        app.launchArguments = ["-HabitCalToday", today, "-HabitCalDefaultsSuite", suite] + extra
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

    // MARK: Settings

    private func element(_ label: String) -> XCUIElement {
        popover.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    private func text(_ string: String) -> XCUIElement {
        popover.staticTexts.matching(NSPredicate(format: "value == %@", string)).firstMatch
    }

    private func openSettings() {
        openPopover()
        popover.buttons["Settings"].click()
        XCTAssertTrue(popover.buttons["Back"].waitForExistence(timeout: 5), "Settings didn't open")
    }

    /// October 2026 starts on a Thursday: a Monday-first grid runs Sep 28 – Nov 8, a Sunday-first
    /// grid Sep 27 – Nov 7. Each end proves the order on its own.
    private func assertMondayFirstGrid(_ message: String, line: UInt = #line) {
        XCTAssertTrue(element("Sunday, November 8, 2026").exists, message, line: line)
        XCTAssertFalse(element("Sunday, September 27, 2026").exists, message, line: line)
    }

    func testEscapeLeavesSettingsThenClosesPopover() {
        launch()
        openSettings()
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(
            popover.staticTexts["calendarTitle"].waitForExistence(timeout: 5), "Esc didn't return to the list")
        XCTAssertTrue(popover.exists, "Esc from Settings closed the popover")
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(popover.waitForNonExistence(timeout: 5), "second Esc didn't close the popover")
    }

    func testSettingsBackKeepsDisplayedMonth() {
        launch(today: "2026-10-29")
        openPopover()
        popover.buttons["Next month"].click()
        popover.buttons["Settings"].click()
        popover.buttons["Back"].click()
        XCTAssertEqual(calendarTitle, "November 2026")
    }

    func testOverridingWeekStartReordersCalendarAndPersists() {
        let suite = "uitest-\(UUID().uuidString)"
        launch(today: "2026-10-29", suite: suite, ["-HabitCalMacFirstWeekday", "1"])
        openSettings()
        element("Monday").click()
        popover.buttons["Back"].click()
        assertMondayFirstGrid("calendar didn't reorder to Monday")

        app.terminate()
        launch(today: "2026-10-29", suite: suite, ["-HabitCalMacFirstWeekday", "1"])
        openPopover()
        assertMondayFirstGrid("override didn't survive a relaunch")
    }

    func testMacWeekStartIsUsedUntilOverridden() {
        launch(today: "2026-10-29", ["-HabitCalMacFirstWeekday", "2"])
        openSettings()
        XCTAssertTrue(text("From your Mac's settings").exists)
        element("Sunday").click()
        XCTAssertTrue(text("Your Mac uses Monday").waitForExistence(timeout: 5))
        // Link-style buttons are links, not buttons, to accessibility.
        element("Use Mac setting").click()
        XCTAssertTrue(text("From your Mac's settings").waitForExistence(timeout: 5))
        popover.buttons["Back"].click()
        assertMondayFirstGrid("didn't go back to the Mac's Monday start")
    }

    func testQuitButtonQuits() {
        launch()
        openSettings()
        popover.buttons["Quit HabitCal"].click()
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 5), "Quit didn't quit")
    }

    func testCommandQQuitsWhilePopoverIsOpen() {
        launch()
        openPopover()
        app.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 5), "⌘Q didn't quit")
    }

    func testControlsHaveSpokenLabels() {
        launch()
        openPopover()
        for label in ["Previous month", "Today", "Next month", "Settings"] {
            XCTAssertTrue(popover.buttons[label].exists, "missing \(label)")
        }
        popover.buttons["Settings"].click()
        for label in ["Back", "Quit HabitCal"] {
            XCTAssertTrue(popover.buttons[label].waitForExistence(timeout: 5), "missing \(label)")
        }
        XCTAssertTrue(element("muchfiner.com").exists, "missing muchfiner.com")
        XCTAssertTrue(element("Launch at login").exists, "missing Launch at login")
        XCTAssertTrue(element("Week starts on").exists, "missing Week starts on")
    }

    func testLaunchAtLoginIsDisabledOutsideApplications() {
        // UI tests run the app from DerivedData, which is never /Applications (E.10).
        launch()
        openSettings()
        XCTAssertTrue(text("Move HabitCal to Applications to launch at login").exists)
        XCTAssertFalse(element("Launch at login").isEnabled, "switch should be disabled outside /Applications")
    }
}
