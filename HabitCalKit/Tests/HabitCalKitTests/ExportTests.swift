import Foundation
import Testing

@testable import HabitCalKit

private func oct(_ d: Int) -> Day { Day(year: 2026, month: 10, day: d) }
private let t0 = Date(timeIntervalSince1970: 1_793_000_000)

@Suite("Export")
struct ExportTests {
    @Test func exportWritesShownHabitsInTheSavedFormat() throws {
        var habits = Habits()
        let run = habits.add(HabitDraft(name: "Run", note: "5k", days: [6, 1]), today: oct(1), now: t0)
        habits.toggle(run, on: oct(2), today: oct(29), now: t0)
        let gone = habits.add(HabitDraft(name: "Swim", note: "", days: [2]), today: oct(1), now: t0)
        habits.delete(gone, now: t0)

        let data = try HabitStore.exportData(habits)
        let root = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(root["formatVersion"] as? Int == HabitStore.formatVersion)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("ExportTests-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: directory.appendingPathComponent(HabitStore.fileName))
        guard case .loaded(let loaded) = HabitStore(directory: directory).load() else {
            Issue.record("an export should load as a habits file")
            return
        }
        #expect(loaded.all.map(\.name) == ["Run"])  // shown habits only
        #expect(loaded.records.count == 1)
        #expect(loaded.all[0].isDone(on: oct(2)))
    }

    @Test func exportWithNoHabitsWritesAnEmptyList() throws {
        let data = try HabitStore.exportData(Habits())
        let root = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect((root["habits"] as? [Any])?.isEmpty == true)
    }

    @Test func exportFileNameUsesToday() {
        #expect(
            HabitLabels.exportFileName(today: Day(year: 2026, month: 11, day: 1)) == "HabitCal Habits 2026-11-01.json")
    }
}
