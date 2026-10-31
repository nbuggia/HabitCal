import XCTest

/// Selecting a day in the calendar (T-022). Today is Thursday, October 29, 2026, and the habits are
/// HabitsUITests.seed: Push-ups every day; Run on Fridays and Sundays.
final class DaySelectionUITests: HabitCalUITestCase {
    func testSelectingAPastDayShowsAndFixesItsHabits() {
        launch(seed: HabitsUITests.seed)
        openPopover()
        element("Friday, October 23, 2026").click()
        XCTAssertTrue(element("Friday, October 23, 2026, selected").exists)
        // Run is due on Fridays, so it's in the list, not folded.
        let run = element("Run, not done on October 23")
        XCTAssertTrue(run.waitForExistence(timeout: 5), "Run should be listed for a Friday")
        run.click()
        XCTAssertTrue(element("Run, done on October 23").waitForExistence(timeout: 5), "didn't check off Oct 23")
        XCTAssertEqual(
            popover.descendants(matching: .any)["streaks-Run"].label, "Current streak 0 days, best streak 1 day")
    }

    func testAddingAHabitWhileAPastDayIsSelectedKeepsItInView() {
        launch(seed: HabitsUITests.seed)
        openPopover()
        element("Friday, October 23, 2026").click()
        popover.buttons["Add habit"].click()
        XCTAssertTrue(popover.textFields["nameField"].waitForExistence(timeout: 5), "form didn't open")
        app.typeText("Swim\r")
        // Added today, so not due on October 23: the folded row opens to show it (T-012 B.4).
        XCTAssertTrue(element("Edit Swim").waitForExistence(timeout: 5), "new habit hidden in the folded row")
    }

    func testFutureDayIsReadOnlyAndTodayButtonReturns() {
        launch(seed: HabitsUITests.seed)
        openPopover()
        element("Friday, October 30, 2026").click()
        let run = element("Run, October 30, can't check off a future day")
        XCTAssertTrue(run.waitForExistence(timeout: 5))
        XCTAssertFalse(run.isEnabled, "a future day can't be checked off")

        popover.buttons["Today"].click()
        XCTAssertFalse(element("Friday, October 30, 2026, selected").exists)
        XCTAssertTrue(element("Push-ups, not done today").waitForExistence(timeout: 5))
    }

    func testReopeningSelectsToday() {
        launch(seed: HabitsUITests.seed)
        openPopover()
        element("Friday, October 23, 2026").click()
        XCTAssertTrue(element("Friday, October 23, 2026, selected").exists)
        statusItem.click()
        Thread.sleep(forTimeInterval: 0.5)
        openPopover()
        XCTAssertFalse(element("Friday, October 23, 2026, selected").exists)
        XCTAssertTrue(element("Push-ups, not done today").exists)
    }
}
