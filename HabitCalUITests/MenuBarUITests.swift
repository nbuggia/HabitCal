import XCTest

/// Menu bar: the status item, the popover, the calendar, and Settings.
final class MenuBarUITests: HabitCalUITestCase {
    func testStatusItemOpensAndClosesPopover() {
        launch()
        XCTAssertTrue(statusItem.waitForExistence(timeout: 10), "status item not found")

        statusItem.click()
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
        XCTAssertTrue(popover.buttons["Add habit"].exists, "habit list not shown")
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
        pickWeekStart("Monday")
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
        XCTAssertEqual(weekStartMenu.value as? String, "Monday", "menu doesn't show the Mac's week start")
        popover.buttons["Back"].click()
        assertMondayFirstGrid("calendar doesn't start on the Mac's Monday")
    }

    /// The week-start pop-up menu in Settings (T-033).
    private var weekStartMenu: XCUIElement {
        popover.popUpButtons["Week starts on"]
    }

    private func pickWeekStart(_ day: String) {
        weekStartMenu.click()
        app.menuItems[day].click()
    }

    func testSettingsShowsSyncStatus() {
        let expected = [
            "off": "iCloud: iCloud is off, habits stay on this Mac. "
                + "Sign into iCloud in System Settings to sync your Macs.",
            "waiting": "iCloud: Waiting for iCloud, changes will sync when this Mac is back online.",
            "full": "iCloud: iCloud is full, changes stay on this Mac until there's room.",
            "updateNeeded": "iCloud: Update HabitCal to sync, another Mac has a newer version. "
                + "Habits on this Mac still work.",
        ]
        for (name, spoken) in expected {
            launch(["-HabitCalSyncStatus", name])
            openSettings()
            let row = popover.descendants(matching: .any)["syncStatus"]
            XCTAssertTrue(row.waitForExistence(timeout: 5), "no status row for \(name)")
            XCTAssertEqual(row.label, spoken)
            app.terminate()
        }
    }

    func testSyncNowShowsWhenICloudIsOnAndWaitsWhileSyncing() {
        launch(["-HabitCalSyncStatus", "synced"])
        openSettings()
        XCTAssertTrue(element("Sync Now").waitForExistence(timeout: 5), "no Sync Now")
        XCTAssertTrue(element("Sync Now").isEnabled)
        app.terminate()

        launch(["-HabitCalSyncStatus", "syncing"])
        openSettings()
        XCTAssertTrue(element("Sync Now").waitForExistence(timeout: 5))
        XCTAssertFalse(element("Sync Now").isEnabled, "Sync Now while syncing")
        app.terminate()

        launch(["-HabitCalSyncStatus", "off"])
        openSettings()
        XCTAssertFalse(element("Sync Now").exists, "Sync Now with iCloud off")
    }

    func testTestsNeverSync() {
        // UI tests always pass -HabitCalDataDir, which turns sync off (FM-007, T-039).
        launch()
        openSettings()
        XCTAssertEqual(
            popover.descendants(matching: .any)["syncStatus"].label,
            "iCloud: iCloud is off, habits stay on this Mac. Sign into iCloud in System Settings to sync your Macs.")
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
