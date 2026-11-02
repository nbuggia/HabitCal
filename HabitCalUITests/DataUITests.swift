import XCTest

/// Export and import from Settings (T-035). The system's file panels run out of process, so the Debug
/// answers (`-HabitCalExportTo`, `-HabitCalImportFrom`, `-HabitCalImportFile`, `-HabitCalConfirmImport`)
/// stand in for them; the panels themselves are manual tests. Today is Thursday, October 29, 2026.
final class DataUITests: HabitCalUITestCase {
    /// One habit, Read, every day, as a version 1 file.
    private static let readFile = """
        { "formatVersion": 1, "habits": [ { "id": "5A1B2C3D-0000-4000-8000-000000000001", "name": "Read",
          "note": "", "addedOn": "2026-10-01",
          "schedule": [ { "from": "2026-10-01", "days": ["sun", "mon", "tue", "wed", "thu", "fri", "sat"] } ],
          "checkOffs": [] } ] }
        """

    private func base64(_ text: String) -> String {
        Data(text.utf8).base64EncodedString()
    }

    private func openSettings() {
        openPopover()
        popover.buttons["Settings"].click()
        XCTAssertTrue(popover.buttons["Back"].waitForExistence(timeout: 5), "Settings didn't open")
    }

    /// Clicks a Data button in Settings; the panel closes before the dialog (T-035), so wait for it to go.
    private func clickData(_ label: String) {
        openSettings()
        element(label).click()
        XCTAssertTrue(popover.waitForNonExistence(timeout: 5), "the panel should close before the dialog")
        Thread.sleep(forTimeInterval: 0.5)  // the reopen guard
    }

    private func row(_ name: String) -> XCUIElement {
        element("Edit \(name)")
    }

    func testExportThenImportRestoresTheList() {
        launch(
            seed: HabitsUITests.seed,
            ["-HabitCalExportTo", "export.json", "-HabitCalImportFrom", "export.json", "-HabitCalConfirmImport", "yes"])
        clickData("Export habits")
        openPopover()
        popover.buttons["Add habit"].click()
        XCTAssertTrue(popover.textFields["nameField"].waitForExistence(timeout: 5))
        app.typeText("Swim\r")
        XCTAssertTrue(row("Swim").waitForExistence(timeout: 5))
        statusItem.click()
        Thread.sleep(forTimeInterval: 0.5)

        clickData("Import habits")
        openPopover()
        XCTAssertTrue(row("Push-ups").waitForExistence(timeout: 5), "the export's habits came back")
        XCTAssertFalse(row("Swim").exists, "the import replaced the list")
    }

    func testImportReplacesAfterConfirming() {
        launch(
            seed: HabitsUITests.seed,
            [
                "-HabitCalImportFile", base64(Self.readFile), "-HabitCalConfirmImport", "yes",
                "-HabitCalMacFirstWeekday", "1",
            ])
        openSettings()
        popover.popUpButtons["Week starts on"].click()
        app.menuItems["Monday"].click()
        popover.buttons["Back"].click()
        statusItem.click()
        Thread.sleep(forTimeInterval: 0.5)

        clickData("Import habits")
        openPopover()
        XCTAssertTrue(row("Read").waitForExistence(timeout: 5), "imported habit missing")
        XCTAssertFalse(row("Push-ups").exists, "old habits should be replaced")
        popover.buttons["Settings"].click()
        XCTAssertEqual(
            popover.popUpButtons["Week starts on"].value as? String, "Monday", "an import doesn't touch settings (B.14)"
        )
    }

    func testImportCancelledChangesNothing() {
        launch(
            seed: HabitsUITests.seed, ["-HabitCalImportFile", base64(Self.readFile), "-HabitCalConfirmImport", "no"])
        clickData("Import habits")
        openPopover()
        XCTAssertTrue(row("Push-ups").waitForExistence(timeout: 5))
        XCTAssertFalse(row("Read").exists, "Cancel in the confirmation changes nothing")
        app.terminate()

        launch(seed: HabitsUITests.seed, ["-HabitCalImportFrom", "cancel"])
        clickData("Import habits")
        openPopover()
        XCTAssertTrue(row("Push-ups").waitForExistence(timeout: 5), "Cancel in the dialog changes nothing")
    }

    func testExportCancelledWritesNothing() {
        // Nothing to import afterwards: the cancelled export wrote no file, so the import can't open it.
        launch(
            seed: HabitsUITests.seed,
            ["-HabitCalExportTo", "cancel", "-HabitCalImportFrom", "export.json", "-HabitCalConfirmImport", "yes"])
        clickData("Export habits")
        clickData("Import habits")
        openPopover()
        XCTAssertTrue(row("Push-ups").waitForExistence(timeout: 5), "list unchanged: no file was written")
    }

    func testImportWithNoHabitsDoesNotAsk() {
        // No confirmation answer is given, which would refuse; with no habits it isn't asked (B.7).
        launch(["-HabitCalImportFile", base64(Self.readFile)])
        clickData("Import habits")
        openPopover()
        XCTAssertTrue(row("Read").waitForExistence(timeout: 5), "imported without asking")
    }

    func testImportRefusesANewerFile() {
        launch(
            seed: HabitsUITests.seed,
            ["-HabitCalImportFile", base64(#"{ "formatVersion": 3, "habits": [] }"#), "-HabitCalConfirmImport", "yes"])
        clickData("Import habits")
        openPopover()
        XCTAssertTrue(row("Push-ups").waitForExistence(timeout: 5), "a newer file changes nothing (E.4)")
    }

    func testExportAndImportDisabledWhileUnreadable() {
        launch(seed: "{ not json")
        openSettings()
        XCTAssertFalse(element("Export habits").isEnabled)
        XCTAssertFalse(element("Import habits").isEnabled)
    }

    func testDataButtonsHaveSpokenLabels() {
        launch()
        openSettings()
        XCTAssertTrue(element("Export habits").exists)
        XCTAssertTrue(element("Import habits").exists)
    }
}
