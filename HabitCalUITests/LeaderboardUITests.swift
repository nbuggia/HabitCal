import XCTest

/// The consistency leaderboard (T-016). Today is Thursday, October 29, 2026, and the habits are
/// HabitsUITests.seed: Push-ups every day from October 1, done only on the 27th; Run on Fridays and
/// Sundays from September 1, never done. Today isn't done, so it isn't counted yet.
final class LeaderboardUITests: HabitCalUITestCase {
    private var score: XCUIElement {
        popover.descendants(matching: .any)["leaderboardScore"]
    }

    private func rowLabel(_ name: String) -> String {
        popover.descendants(matching: .any)["leaderboard-\(name)"].label
    }

    /// Weekday 1 is Sunday, 2 Monday: the week tab counts from the week start in effect.
    private func openLeaderboard(firstWeekday: String = "1") {
        launch(seed: HabitsUITests.seed, ["-HabitCalMacFirstWeekday", firstWeekday])
        openPopover()
        popover.buttons["Leaderboard"].click()
        XCTAssertTrue(score.waitForExistence(timeout: 5), "leaderboard didn't open")
    }

    func testLeaderboardOpensRanksAndSwitchesRange() {
        openLeaderboard()
        // Week, Sunday to date (Oct 25–28): Push-ups 1 of 4, Run 0 of 1 (Sun 25); overall 1 of 5.
        XCTAssertTrue(element("Week, Sunday to date").exists)
        XCTAssertEqual(score.label, "20 percent of due days done across all habits")
        XCTAssertEqual(rowLabel("Push-ups"), "1st, Push-ups, 25 percent")
        XCTAssertEqual(rowLabel("Run"), "2nd, Run, 0 percent")
        // The detail lines: the week's events and completions, then the current streak (missed the 28th).
        XCTAssertEqual(
            popover.descendants(matching: .any)["leaderboard-Push-ups"].value as? String,
            "4 events, 1 completed, 0 streak")

        // Month to date (Oct 1–28): Push-ups 1 of 28, Run 0 of 8; overall 1 of 36.
        element("Month, Month to date").click()
        XCTAssertEqual(score.label, "3 percent of due days done across all habits")
        XCTAssertEqual(rowLabel("Push-ups"), "1st, Push-ups, 4 percent")
    }

    func testWeekCountsFromMondayWhenTheWeekStartsMonday() {
        openLeaderboard(firstWeekday: "2")
        // Week, Monday to date (Oct 26–28): Push-ups 1 of 3, Run nothing due; overall 1 of 3.
        XCTAssertTrue(element("Week, Monday to date").exists)
        XCTAssertEqual(score.label, "33 percent of due days done across all habits")
        XCTAssertEqual(rowLabel("Run"), "2nd, Run, no due days")
    }

    func testEscFromLeaderboardReturnsToList() {
        openLeaderboard()
        element("Month, Month to date").click()
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(popover.staticTexts["calendarTitle"].waitForExistence(timeout: 5), "Esc didn't go back")
        XCTAssertTrue(popover.exists, "Esc from the leaderboard should go back, not close")

        // It opens on Week again.
        popover.buttons["Leaderboard"].click()
        XCTAssertTrue(score.waitForExistence(timeout: 5))
        XCTAssertEqual(score.label, "20 percent of due days done across all habits")
        popover.buttons["Back"].click()
        XCTAssertTrue(popover.staticTexts["calendarTitle"].waitForExistence(timeout: 5), "Back didn't go back")
    }
}
