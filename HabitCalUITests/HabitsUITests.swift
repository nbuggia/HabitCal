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

    func testEmptyListShowsPrompt() {
        launch()
        openPopover()
        XCTAssertTrue(text("No habits").exists)
    }

    func testCheckingOffTodayFillsTheButton() {
        launch(seed: Self.seed)
        openPopover()
        let button = element("Push-ups, not done today")
        XCTAssertTrue(button.exists, "done button missing")
        button.click()
        XCTAssertTrue(element("Push-ups, done today").waitForExistence(timeout: 5))
        element("Push-ups, done today").click()
        XCTAssertTrue(element("Push-ups, not done today").waitForExistence(timeout: 5), "second click didn't undo")
    }

    func testHabitsNotDueTodayAreNotListed() {
        launch(seed: Self.seed)
        openPopover()
        XCTAssertTrue(element("Push-ups, not done today").exists)
        XCTAssertFalse(element("Edit Run").exists, "Run isn't due on Thursday, so it isn't listed")
        XCTAssertFalse(text("1 not due today").exists, "no folded row")
        showRunsSunday()
    }

    func testNothingDueTodayWhenNoHabitIsDue() {
        let runOnly = Self.seed.replacingOccurrences(of: "\"Push-ups\"", with: "\"Swim\"")
            .replacingOccurrences(
                of: "[\"sun\", \"mon\", \"tue\", \"wed\", \"thu\", \"fri\", \"sat\"]", with: "[\"sat\"]")
        launch(seed: runOnly)
        openPopover()
        XCTAssertTrue(text("Nothing due today").exists, "no Nothing due today")
        XCTAssertFalse(text("No habits").exists)
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
        showRunsSunday()
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
        for label in ["Add habit", "Edit Push-ups", "Push-ups, not done today"] {
            XCTAssertTrue(element(label).exists, "missing \(label)")
        }
        XCTAssertFalse(popover.descendants(matching: .any)["strip-Push-ups"].exists, "the strip is hidden (T-041)")

        popover.buttons["Edit Push-ups"].click()
        for label in ["Name", "Notes", "Close", "Delete habit"] + ["Sunday", "Monday", "Saturday"] {
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
        // Fix the 28th from the calendar (T-022): the strip isn't clickable (T-041).
        element("Wednesday, October 28, 2026").click()
        element("Push-ups, not done on October 28").click()
        XCTAssertEqual(streaks.label, "Current streak 3 days, best streak 3 days")
        showRunsSunday()
        XCTAssertEqual(
            popover.descendants(matching: .any)["streaks-Run"].label, "Current streak 0 days, best streak 0 days")
    }
}
