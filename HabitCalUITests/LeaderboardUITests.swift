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

    private func openLeaderboard() {
        launch(seed: HabitsUITests.seed)
        openPopover()
        popover.buttons["Leaderboard"].click()
        XCTAssertTrue(score.waitForExistence(timeout: 5), "leaderboard didn't open")
    }

    func testLeaderboardOpensRanksAndSwitchesRange() {
        openLeaderboard()
        // Past 7 days (Oct 23–28): Push-ups 1 of 6, Run 0 of 2 (Fri 23, Sun 25); overall 1 of 8.
        XCTAssertEqual(score.label, "13 percent of due days done across all habits")
        XCTAssertEqual(rowLabel("Push-ups"), "1st, Push-ups, 17 percent")
        XCTAssertEqual(rowLabel("Run"), "2nd, Run, 0 percent")

        // Past 30 days (Sep 30 – Oct 28): Push-ups 1 of 29 (due before it was added too, T-028), Run 0
        // of 8; overall 1 of 37.
        element("Past 30 days").click()
        XCTAssertEqual(score.label, "3 percent of due days done across all habits")
        XCTAssertEqual(rowLabel("Push-ups"), "1st, Push-ups, 3 percent")
    }

    func testEscFromLeaderboardReturnsToList() {
        openLeaderboard()
        element("Past 30 days").click()
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(popover.staticTexts["calendarTitle"].waitForExistence(timeout: 5), "Esc didn't go back")
        XCTAssertTrue(popover.exists, "Esc from the leaderboard should go back, not close")

        // It opens on Past 7 days again.
        popover.buttons["Leaderboard"].click()
        XCTAssertTrue(score.waitForExistence(timeout: 5))
        XCTAssertEqual(score.label, "13 percent of due days done across all habits")
        popover.buttons["Back"].click()
        XCTAssertTrue(popover.staticTexts["calendarTitle"].waitForExistence(timeout: 5), "Back didn't go back")
    }
}
