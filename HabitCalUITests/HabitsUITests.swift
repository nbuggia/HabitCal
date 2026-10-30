import XCTest

/// Habits: rows, check-offs, the strip, and saving. Today is Thursday, October 29, 2026.
final class HabitsUITests: HabitCalUITestCase {
    /// Push-ups every day; Run on Fridays and Sundays. Both added October 1.
    static let seed = """
        {
          "formatVersion": 1,
          "habits": [
            { "id": "0E984725-C51C-4BF4-9960-E1C80E27ABA0", "name": "Push-ups", "note": "3 sets of 20",
              "addedOn": "2026-10-01",
              "schedule": [ { "from": "2026-10-01", "days": ["sun", "mon", "tue", "wed", "thu", "fri", "sat"] } ],
              "checkOffs": ["2026-10-27"] },
            { "id": "6F9619FF-8B86-D011-B42D-00CF4FC964FF", "name": "Run", "note": "",
              "addedOn": "2026-10-01",
              "schedule": [ { "from": "2026-10-01", "days": ["fri", "sun"] } ],
              "checkOffs": [] }
          ]
        }
        """

    private func strip(_ name: String) -> XCUIElement {
        popover.descendants(matching: .any)["strip-\(name)"]
    }

    private func stripValue(_ name: String) -> String {
        strip(name).value as? String ?? ""
    }

    /// Clicks the strip square for `day` of the displayed month.
    private func clickStripDay(_ name: String, day: Int) {
        let offset = (Double(day) - 0.5) / 31
        strip(name).coordinate(withNormalizedOffset: CGVector(dx: offset, dy: 0.5)).click()
    }

    func testEmptyListShowsPrompt() {
        launch()
        openPopover()
        XCTAssertTrue(text("No habits yet. Add one to start a streak.").exists)
    }

    func testCheckingOffTodayFillsTheButtonAndTodaysSquare() {
        launch(seed: Self.seed)
        openPopover()
        let button = element("Push-ups, not done today")
        XCTAssertTrue(button.exists, "done button missing")
        XCTAssertEqual(stripValue("Push-ups"), "October 29, missed")
        button.click()
        XCTAssertTrue(element("Push-ups, done today").waitForExistence(timeout: 5))
        XCTAssertEqual(stripValue("Push-ups"), "October 29, done")
        element("Push-ups, done today").click()
        XCTAssertTrue(element("Push-ups, not done today").waitForExistence(timeout: 5), "second click didn't undo")
        XCTAssertTrue(element("Run, not scheduled today").exists, "Run isn't due on Thursday")
    }

    func testFixingAMissedDayInTheStrip() {
        launch(seed: Self.seed)
        openPopover()
        clickStripDay("Run", day: 25)  // a Sunday
        XCTAssertEqual(stripValue("Run"), "October 25, done")
        clickStripDay("Run", day: 26)  // Monday: not due, nothing happens
        XCTAssertEqual(stripValue("Run"), "October 26, not scheduled")
        clickStripDay("Run", day: 30)  // Friday, future: nothing happens
        XCTAssertEqual(stripValue("Run"), "October 30")

        popover.buttons["Previous month"].click()
        clickStripDay("Run", day: 27)  // Sunday, September 27: before Run was added
        XCTAssertEqual(stripValue("Run"), "September 27, not scheduled")
    }

    func testHabitsSurviveRelaunch() {
        let folder = "uitest-\(UUID().uuidString)"
        launch(dataFolder: folder, seed: Self.seed)
        openPopover()
        element("Push-ups, not done today").click()
        XCTAssertTrue(element("Push-ups, done today").waitForExistence(timeout: 5))

        app.terminate()
        launch(dataFolder: folder)
        openPopover()
        XCTAssertTrue(element("Push-ups, done today").exists, "check-off didn't survive a relaunch")
        XCTAssertTrue(text("Run").exists)
    }

    func testStripIsOneTabStopThatArrowsAndSpaceDrive() {
        launch(seed: Self.seed)
        openPopover()
        XCTAssertEqual(stripValue("Push-ups"), "October 29, missed")
        // Tab until ← moves the strip's day: proof the strip has keyboard focus. It's one Tab stop,
        // so a few presses at most.
        var focused = false
        for _ in 0..<6 {
            app.typeKey(.tab, modifierFlags: [])
            app.typeKey(.leftArrow, modifierFlags: [])
            if stripValue("Push-ups") == "October 28, missed" {
                focused = true
                break
            }
        }
        XCTAssertTrue(focused, "the strip never took keyboard focus")
        app.typeKey(.space, modifierFlags: [])
        XCTAssertEqual(stripValue("Push-ups"), "October 28, done")
        app.typeKey(.rightArrow, modifierFlags: [])
        XCTAssertEqual(stripValue("Push-ups"), "October 29, missed")
    }
}
