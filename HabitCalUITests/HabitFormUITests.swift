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

        XCTAssertTrue(row("Run").waitForExistence(timeout: 5), "new habit not in the list")
        XCTAssertEqual(row("Run").value as? String, "Fri, Sun", "wrong schedule label")
        XCTAssertTrue(element("Run, not scheduled today").exists)
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
        popover.buttons["Edit Run"].click()
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        XCTAssertEqual(nameField.value as? String, "Run")
        app.typeKey("a", modifierFlags: .command)
        app.typeText("Long run")
        popover.buttons["Monday"].click()
        XCTAssertTrue(text("The new schedule starts today. Past days, and your streak, keep the old one.").exists)
        popover.buttons["Save"].click()

        XCTAssertTrue(row("Long run").waitForExistence(timeout: 5))
        XCTAssertEqual(row("Long run").value as? String, "Mon, Fri, Sun")
    }

    func testDeletingAHabitAsksFirstThenRemovesIt() {
        launch(seed: HabitsUITests.seed)
        openPopover()
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
        popover.buttons["Edit Run"].click()
        popover.buttons["Delete habit"].click()
        XCTAssertTrue(text("Delete “Run”?").waitForExistence(timeout: 5))
        popover.buttons["confirmCancel"].click()
        XCTAssertFalse(text("Delete “Run”?").exists)
        popover.buttons["Cancel"].click()
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
