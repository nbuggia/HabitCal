import Foundation
import Testing

@testable import HabitCalKit

private func oct(_ d: Int) -> Day { Day(year: 2026, month: 10, day: d) }
private let today = oct(29)
private let t0 = Date(timeIntervalSince1970: 1_793_000_000)

@Suite("Import")
struct ImportTests {
    private let directory: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("ImportTests-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func file(_ text: String, name: String = "habits.json") throws -> URL {
        let url = directory.appendingPathComponent(name)
        try Data(text.utf8).write(to: url)
        return url
    }

    private func fixture(_ name: String) throws -> URL {
        try #require(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
    }

    @Test func importAcceptsVersion1And2() throws {
        #expect(try HabitStore.importHabits(from: fixture("habits-v1")).all.map(\.name) == ["Run", "Push-ups"])
        #expect(try HabitStore.importHabits(from: fixture("habits-v2")).all.map(\.name) == ["Run"])
    }

    @Test func importRefusesNewerFormat() throws {
        let url = try file(#"{ "formatVersion": 3, "habits": [] }"#)
        #expect(throws: HabitStore.ImportError.newerFormat(3)) { try HabitStore.importHabits(from: url) }
    }

    @Test func importRefusesNonHabitCalFilesAndMissingVersion() throws {
        for text in ["{ not json", #"{ "habits": [] }"#, #"{ "formatVersion": 2, "habits": [], "tags": [] }"#, "[]"] {
            let url = try file(text)
            #expect {
                try HabitStore.importHabits(from: url)
            } throws: { error in
                if case HabitStore.ImportError.notHabitCal = error { return true }
                return false
            }
        }
    }

    @Test func importRefusesFilesOverTenMegabytesWithoutReadingThem() throws {
        let url = directory.appendingPathComponent("big.json")
        FileManager.default.createFile(atPath: url.path, contents: nil)
        let handle = try FileHandle(forWritingTo: url)
        try handle.truncate(atOffset: UInt64(HabitStore.importLimit + 1))  // sparse: never read
        try handle.close()
        #expect {
            try HabitStore.importHabits(from: url)
        } throws: { error in
            if case HabitStore.ImportError.notHabitCal = error { return true }
            return false
        }
    }

    @Test func importReportsAFileItCantOpen() throws {
        let url = directory.appendingPathComponent("missing.json")
        #expect {
            try HabitStore.importHabits(from: url)
        } throws: { error in
            if case HabitStore.ImportError.cantOpen = error { return true }
            return false
        }
    }

    @Test func exportThenImportKeepsNamesSchedulesAndCheckOffs() throws {
        var habits = Habits()
        let run = habits.add(HabitDraft(name: "Run", note: "5k", days: [6, 1]), today: oct(1), now: t0)
        habits.toggle(run, on: oct(2), today: today, now: t0)
        let url = directory.appendingPathComponent("export.json")
        try HabitStore.exportData(habits).write(to: url)
        var other = Habits()
        other.add(HabitDraft(name: "Swim", note: "", days: [2]), today: oct(1), now: t0)
        other.replaceAll(with: try HabitStore.importHabits(from: url).all, now: t0.addingTimeInterval(5))
        let imported = try #require(other.all.first)
        #expect(other.all.count == 1)
        #expect(imported.name == "Run" && imported.note == "5k")
        #expect(imported.schedule == habits[run]?.schedule)
        #expect(imported.addedOn == oct(1))
        #expect(imported.checkOffs == [oct(2)])
    }

    @Test func replaceAllReturnsDeletedAndAddedIDs() {
        var habits = Habits()
        let old = habits.add(HabitDraft(name: "Run", note: "", days: [6]), today: oct(1), now: t0)
        var file = Habits()
        file.add(HabitDraft(name: "Swim", note: "", days: [2]), today: oct(1), now: t0)
        let changed = habits.replaceAll(with: file.all, now: t0.addingTimeInterval(1))
        let added = habits.all.map(\.id)
        #expect(changed == Set([old] + added))
    }

    // MARK: Confirmation

    @Test func lastCheckOffSkipsUnchecksAndDeletedHabits() {
        var habits = Habits()
        let run = habits.add(HabitDraft(name: "Run", note: "", days: Set(1...7)), today: oct(1), now: t0)
        habits.toggle(run, on: oct(20), today: today, now: t0)
        habits.toggle(run, on: oct(25), today: today, now: t0)
        habits.toggle(run, on: oct(25), today: today, now: t0)  // unchecked again
        let gone = habits.add(HabitDraft(name: "Swim", note: "", days: Set(1...7)), today: oct(1), now: t0)
        habits.toggle(gone, on: oct(28), today: today, now: t0)
        habits.delete(gone, now: t0)
        #expect(HabitLabels.lastCheckOff(habits, today: today) == "last checked off Oct 20")
        #expect(HabitLabels.lastCheckOff(Habits(), today: today) == "no check-offs")
    }

    @Test func lastCheckOffAddsTheYearWhenNotThisYear() {
        var habits = Habits()
        let run = habits.add(HabitDraft(name: "Run", note: "", days: Set(1...7)), today: oct(1), now: t0)
        habits.toggle(run, on: Day(year: 2025, month: 3, day: 2), today: today, now: t0)
        #expect(HabitLabels.lastCheckOff(habits, today: today) == "last checked off Mar 2, 2025")
    }

    @Test func importConfirmationNamesCountsAndLastCheckOffs() {
        var current = Habits()
        for name in ["Run", "Read", "Swim", "Walk", "Stretch"] {
            let id = current.add(HabitDraft(name: name, note: "", days: Set(1...7)), today: oct(1), now: t0)
            current.toggle(id, on: oct(28), today: today, now: t0)
        }
        var incoming = Habits()
        incoming.add(HabitDraft(name: "Run", note: "", days: [6]), today: oct(1), now: t0)
        let label = HabitLabels.importConfirmation(
            current: current, incoming: incoming, fileName: "HabitCal Habits 2026-03-02.json", syncOn: false,
            today: today)
        #expect(label.title == "Replace your habits?")
        #expect(
            label.message
                == "Your 5 habits (last checked off Oct 28) will be replaced by the 1 habit in “HabitCal Habits 2026-03-02.json” (no check-offs). This can't be undone."
        )
    }

    @Test func importConfirmationSaysAllYourMacsWhenSyncing() {
        var current = Habits()
        current.add(HabitDraft(name: "Run", note: "", days: [6]), today: oct(1), now: t0)
        let label = HabitLabels.importConfirmation(
            current: current, incoming: Habits(), fileName: "x.json", syncOn: true, today: today)
        #expect(
            label.message.hasPrefix("Your 1 habit on all your Macs (no check-offs) will be replaced by the 0 habits"))
    }
}
