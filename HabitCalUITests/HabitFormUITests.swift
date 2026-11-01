import XCTest

/// The habit form: adding, editing, deleting, and Esc. Today is Thursday, October 29, 2026.
final class HabitFormUITests: HabitCalUITestCase {
    private var nameField: XCUIElement { popover.textFields["nameField"] }
    private var notesField: XCUIElement { popover.textViews["notesField"] }

    /// A habit's row, found by its name button ("Edit Run"), whose value is the schedule label.
    private func row(_ name: String) -> XCUIElement {
        element("Edit \(name)")
    }

    private func openAddForm() {
        openPopover()
        popover.buttons["Add habit"].click()
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "form didn't open")
    }

    func testAddingAHabitShowsItWithItsScheduleLabel() {
        launch()
        openAddForm()
        XCTAssertFalse(popover.buttons["Add"].isEnabled, "Add should wait for a name")
        app.typeText("Run")
        for day in ["Monday", "Tuesday", "Wednesday", "Thursday", "Saturday"] {
            popover.buttons[day].click()
        }
        notesField.click()
        app.typeText("5k loop")
        XCTAssertTrue(popover.buttons["Add"].isEnabled)
        popover.buttons["Add"].click()

        // Run isn't due on Thursday, so it isn't listed; it shows on its days (T-036).
        XCTAssertTrue(popover.staticTexts["calendarTitle"].waitForExistence(timeout: 5), "didn't return to the list")
        XCTAssertFalse(row("Run").exists, "Run isn't due today")
        element("Friday, October 30, 2026").click()
        XCTAssertTrue(row("Run").waitForExistence(timeout: 5), "new habit not on its Friday")
        XCTAssertEqual(row("Run").value as? String, "Fri, Sun", "wrong schedule label")
    }

    func testAddIsDisabledWithoutADay() {
        launch()
        openAddForm()
        app.typeText("Stretch")
        for day in ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"] {
            popover.buttons[day].click()
        }
        XCTAssertFalse(popover.buttons["Add"].isEnabled)
        XCTAssertTrue(text("Pick at least one day.").exists)
    }

    func testTypingInTheNameFieldKeepsFocus() {
        launch()
        openAddForm()
        app.typeText("Push-ups")
        XCTAssertEqual(nameField.value as? String, "Push-ups")
    }

    func testNameStopsAtFortyCharacters() {
        launch()
        openAddForm()
        app.typeText(String(repeating: "a", count: 45))
        XCTAssertEqual((nameField.value as? String)?.count, 40)
    }

    func testReturnInTheNameFieldAddsTheHabit() {
        launch()
        openAddForm()
        app.typeText("Read\r")
        XCTAssertTrue(row("Read").waitForExistence(timeout: 5))
        XCTAssertEqual(row("Read").value as? String, "Every day")
    }

    func testEditingAHabitRenamesItAndChangesItsDays() {
        launch(seed: HabitsUITests.seed)
        openPopover()
        showRunsSunday()
        popover.buttons["Edit Run"].click()
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        XCTAssertEqual(nameField.value as? String, "Run")
        // The name is selected when the form opens, so typing replaces it (B.9).
        app.typeText("Long run")
        XCTAssertEqual(nameField.value as? String, "Long run")
        popover.buttons["Monday"].click()
        XCTAssertTrue(text("The new schedule starts today. Past days, and your streak, keep the old one.").exists)
        XCTAssertFalse(popover.buttons["Save"].exists, "edits save as they're made (T-038)")
        popover.buttons["Close"].click()

        XCTAssertTrue(row("Long run").waitForExistence(timeout: 5))
        XCTAssertEqual(row("Long run").value as? String, "Mon, Fri, Sun")
    }

    func testEditsSaveAsTheyAreMadeAndSurviveAClose() {
        launch(seed: HabitsUITests.seed)
        openPopover()
        popover.buttons["Edit Push-ups"].click()
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        app.typeText("Squats")
        app.typeKey(.escape, modifierFlags: [])  // Esc closes like Close; the edit is already saved
        XCTAssertTrue(row("Squats").waitForExistence(timeout: 5), "the rename wasn't saved")
    }

    func testUntickingTodayAndTickingItBackKeepsTodaysCheckOff() {
        launch(seed: HabitsUITests.seed)
        openPopover()
        element("Push-ups, not done today").click()
        XCTAssertTrue(element("Push-ups, done today").waitForExistence(timeout: 5))
        popover.buttons["Edit Push-ups"].click()
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        popover.buttons["Thursday"].click()  // today stops being due...
        popover.buttons["Thursday"].click()  // ...and is due again
        popover.buttons["Close"].click()
        XCTAssertTrue(element("Push-ups, done today").waitForExistence(timeout: 5), "today's check-off was lost")
    }

    func testDeletingAHabitAsksFirstThenRemovesIt() {
        launch(seed: HabitsUITests.seed)
        openPopover()
        showRunsSunday()
        row("Run").rightClick()
        let deleteItem = app.menuItems["Delete…"]
        XCTAssertTrue(deleteItem.waitForExistence(timeout: 5), "right-click menu missing Delete…")
        XCTAssertTrue(app.menuItems["Edit…"].exists)
        deleteItem.click()
        XCTAssertTrue(text("Delete “Run”?").waitForExistence(timeout: 5), "no confirmation")
        popover.buttons["Delete"].click()
        XCTAssertTrue(row("Push-ups").waitForExistence(timeout: 5), "didn't return to the list")
        XCTAssertFalse(row("Run").exists, "Run wasn't deleted")
    }

    func testCancellingTheDeleteConfirmationKeepsTheHabit() {
        launch(seed: HabitsUITests.seed)
        openPopover()
        showRunsSunday()
        let listHeight = popover.frame.height
        popover.buttons["Edit Run"].click()
        popover.buttons["Delete habit"].click()
        XCTAssertTrue(text("Delete “Run”?").waitForExistence(timeout: 5))
        // The panel grows to fit the confirmation instead of clipping it (T-037).
        let delete = popover.buttons["Delete"]
        XCTAssertTrue(popover.frame.contains(delete.frame), "Delete is cut off by the panel")
        XCTAssertGreaterThanOrEqual(popover.frame.height, listHeight)
        popover.buttons["confirmCancel"].click()
        XCTAssertFalse(text("Delete “Run”?").exists)
        XCTAssertTrue(popover.buttons["confirmCancel"].waitForNonExistence(timeout: 5))
        popover.buttons["Close"].click()
        XCTAssertTrue(row("Run").waitForExistence(timeout: 5))
    }

    func testEscapeInFormReturnsToList() {
        launch()
        openAddForm()
        app.typeText("Half-typed")
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(popover.staticTexts["calendarTitle"].waitForExistence(timeout: 5), "Esc didn't leave the form")
        XCTAssertFalse(row("Half-typed").exists, "cancelled habit was saved")
    }

    func testEscapeInNotesReturnsToList() {
        launch()
        openAddForm()
        app.typeText("Walk")
        notesField.click()
        app.typeText("After lunch")
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(popover.staticTexts["calendarTitle"].waitForExistence(timeout: 5), "Esc didn't leave the form")
    }
}
