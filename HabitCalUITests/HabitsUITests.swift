import XCTest

/// Habits: rows, check-offs, the strip, and saving. Today is Thursday, October 29, 2026.
final class HabitsUITests: HabitCalUITestCase {
    /// Push-ups every day, added October 1; Run on Fridays and Sundays, added September 1.
    static let seed = """
        {
          "formatVersion": 1,
          "habits": [
            { "id": "0E984725-C51C-4BF4-9960-E1C80E27ABA0", "name": "Push-ups", "note": "3 sets of 20",
              "addedOn": "2026-10-01",
              "schedule": [ { "from": "2026-10-01", "days": ["sun", "mon", "tue", "wed", "thu", "fri", "sat"] } ],
              "checkOffs": ["2026-10-27"] },
            { "id": "6F9619FF-8B86-D011-B42D-00CF4FC964FF", "name": "Run", "note": "",
              "addedOn": "2026-09-01",
              "schedule": [ { "from": "2026-09-01", "days": ["fri", "sun"] } ],
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
    }

    func testHabitsNotDueTodayFoldIntoARow() {
        launch(seed: Self.seed)
        openPopover()
        XCTAssertTrue(element("Push-ups, not done today").exists)
        XCTAssertFalse(element("Edit Run").exists, "Run isn't due on Thursday, so it starts folded away")
        XCTAssertEqual(notDueRow.label, "1 habit not due today")
        XCTAssertEqual(notDueRow.value as? String, "collapsed")

        notDueRow.click()
        XCTAssertTrue(element("Run, not scheduled today").waitForExistence(timeout: 5), "folded row didn't open")
        XCTAssertEqual(notDueRow.value as? String, "expanded")
        clickStripDay("Run", day: 25)  // a Sunday: past days still fix from the strip (B.6)
        XCTAssertEqual(stripValue("Run"), "October 25, done")
        notDueRow.click()
        XCTAssertFalse(element("Edit Run").exists, "folded row didn't close")

        // It starts closed on every open.
        notDueRow.click()
        statusItem.click()
        Thread.sleep(forTimeInterval: 0.5)
        openPopover()
        XCTAssertEqual(notDueRow.value as? String, "collapsed")
        XCTAssertFalse(element("Edit Run").exists)
    }

    func testEscStillClosesAfterFoldingAwayTheFocusedStrip() {
        launch(seed: Self.seed)
        openPopover()
        showNotDue()
        // Tab until ← moves Run's day: proof Run's strip has keyboard focus.
        var focused = false
        for _ in 0..<8 {
            app.typeKey(.tab, modifierFlags: [])
            app.typeKey(.leftArrow, modifierFlags: [])
            if stripValue("Run") == "October 28, not scheduled" {
                focused = true
                break
            }
        }
        XCTAssertTrue(focused, "Run's strip never took keyboard focus")
        notDueRow.click()
        XCTAssertFalse(element("Edit Run").exists, "folded row didn't close")
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(popover.waitForNonExistence(timeout: 5), "Esc didn't close the popover")
    }

    func testNothingDueTodayShowsAboveTheFoldedRow() {
        let runOnly = Self.seed.replacingOccurrences(of: "\"Push-ups\"", with: "\"Swim\"")
            .replacingOccurrences(
                of: "[\"sun\", \"mon\", \"tue\", \"wed\", \"thu\", \"fri\", \"sat\"]", with: "[\"sat\"]")
        launch(seed: runOnly)
        openPopover()
        XCTAssertTrue(text("Nothing due today").exists, "no Nothing due today")
        XCTAssertEqual(notDueRow.label, "2 habits not due today")
        XCTAssertLessThan(text("Nothing due today").frame.minY, notDueRow.frame.minY, "should sit above the folded row")
        XCTAssertFalse(text("No habits yet. Add one to start a streak.").exists)
    }

    func testFixingAMissedDayInTheStrip() {
        launch(seed: Self.seed)
        openPopover()
        showNotDue()
        clickStripDay("Run", day: 25)  // a Sunday
        XCTAssertEqual(stripValue("Run"), "October 25, done")
        clickStripDay("Run", day: 26)  // Monday: not due, nothing happens
        XCTAssertEqual(stripValue("Run"), "October 26, not scheduled")
        clickStripDay("Run", day: 30)  // Friday, future: nothing happens
        XCTAssertEqual(stripValue("Run"), "October 30")

        // Fix a day in an earlier month (UC-3).
        popover.buttons["Previous month"].click()
        clickStripDay("Run", day: 27)  // Sunday, September 27
        XCTAssertEqual(stripValue("Run"), "September 27, done")
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
        showNotDue()
        XCTAssertTrue(element("Edit Run").waitForExistence(timeout: 5))
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

    func testUnreadableDataShowsMessageAndDisablesAdd() {
        let folder = "uitest-\(UUID().uuidString)"
        launch(dataFolder: folder, seed: "{ not json")
        openPopover()
        XCTAssertTrue(text("HabitCal couldn't read your habits").exists, "no unreadable message")
        XCTAssertFalse(popover.buttons["Add habit"].isEnabled, "Add should be disabled")

        // Relaunch without a seed: the file must still be the unreadable one, not saved over.
        app.terminate()
        launch(dataFolder: folder)
        openPopover()
        XCTAssertTrue(text("HabitCal couldn't read your habits").exists, "unreadable file was overwritten")
    }

    func testHabitControlsHaveSpokenLabels() {
        launch(seed: Self.seed)
        openPopover()
        XCTAssertTrue(element("1 habit not due today").exists, "missing the folded row's label")
        showNotDue()
        for label in ["Add habit", "Edit Push-ups", "Push-ups, not done today", "Run, not scheduled today"] {
            XCTAssertTrue(element(label).exists, "missing \(label)")
        }
        XCTAssertEqual(strip("Push-ups").label, "Push-ups, October 2026")

        popover.buttons["Edit Push-ups"].click()
        for label in ["Name", "Notes", "Cancel", "Save", "Delete habit"] + ["Sunday", "Monday", "Saturday"] {
            XCTAssertTrue(element(label).waitForExistence(timeout: 5), "missing \(label)")
        }
        XCTAssertTrue(popover.buttons["Monday"].isSelected, "selected days should say so")
    }

    func testCheckingOffUpdatesTheStreakImmediately() {
        // Push-ups: done on the 27th, missed the 28th, today (29th) not done yet.
        launch(seed: Self.seed)
        openPopover()
        let streaks = popover.descendants(matching: .any)["streaks-Push-ups"]
        XCTAssertEqual(streaks.label, "Current streak 0 days, best streak 1 day")
        element("Push-ups, not done today").click()
        XCTAssertEqual(streaks.label, "Current streak 1 day, best streak 1 day")
        clickStripDay("Push-ups", day: 28)
        XCTAssertEqual(streaks.label, "Current streak 3 days, best streak 3 days")
        showNotDue()
        XCTAssertEqual(
            popover.descendants(matching: .any)["streaks-Run"].label, "Current streak 0 days, best streak 0 days")
    }
}
