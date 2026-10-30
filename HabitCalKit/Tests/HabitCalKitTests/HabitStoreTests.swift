import Foundation
import Testing

@testable import HabitCalKit

private func oct(_ d: Int) -> Day { Day(year: 2026, month: 10, day: d) }

@Suite("Saving")
struct HabitStoreTests {
    private let directory: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "HabitStoreTests-\(UUID().uuidString)")
    }

    private var file: URL { directory.appendingPathComponent(HabitStore.fileName) }

    private func write(_ text: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(text.utf8).write(to: file)
    }

    @Test func version1FixtureLoads() throws {
        let fixture = try #require(
            Bundle.module.url(forResource: "habits-v1", withExtension: "json", subdirectory: "Fixtures"))
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: fixture, to: file)

        guard case .loaded(let habits) = HabitStore(directory: directory).load() else {
            Issue.record("fixture didn't load")
            return
        }
        #expect(habits.all.map(\.name) == ["Run", "Push-ups"])
        let run = habits.all[0]
        #expect(run.id == UUID(uuidString: "6F9619FF-8B86-D011-B42D-00CF4FC964FF"))
        #expect(run.note == "5k loop around the park")
        #expect(run.addedOn == oct(1))
        #expect(
            run.schedule == [
                ScheduleEntry(from: oct(1), days: [6, 1]), ScheduleEntry(from: oct(20), days: [2, 4, 6]),
            ])
        #expect(run.checkOffs == [oct(2), oct(4), oct(21)])
        #expect(habits.all[1].days(on: oct(29)) == Set(1...7))
    }

    @Test func savedHabitsLoadBackUnchanged() throws {
        var habits = Habits()
        let id = habits.add(HabitDraft(name: "Run", note: "5k", days: [6, 1]), today: oct(1))
        habits.toggle(id, on: oct(2), today: oct(29))
        habits.update(id, with: HabitDraft(name: "Run", note: "5k", days: [2]), today: oct(20))
        habits.add(HabitDraft(name: "Read", note: "", days: Set(1...7)), today: oct(3))

        let store = HabitStore(directory: directory)
        #expect(store.load() == .empty)
        try store.save(habits)
        #expect(HabitStore(directory: directory).load() == .loaded(habits))
    }

    @Test func savedFileIsSortedAndReadable() throws {
        var habits = Habits()
        let id = habits.add(HabitDraft(name: "Run", note: "", days: [1, 6]), today: oct(1))
        habits.toggle(id, on: oct(4), today: oct(29))
        habits.toggle(id, on: oct(2), today: oct(29))
        let store = HabitStore(directory: directory)
        _ = store.load()
        try store.save(habits)
        let text = try String(contentsOf: file, encoding: .utf8)
        #expect(text.contains("\"formatVersion\" : 1"))
        #expect(text.range(of: "\"sun\"[\\s,]+\"fri\"", options: .regularExpression) != nil)  // week order
        #expect(text.range(of: "\"2026-10-02\"[\\s,]+\"2026-10-04\"", options: .regularExpression) != nil)
    }

    @Test func missingFileLoadsEmpty() {
        #expect(HabitStore(directory: directory).load() == .empty)
    }

    @Test func unreadableFileIsNeverOverwritten() throws {
        try write("{ not json")
        let store = HabitStore(directory: directory)
        guard case .unreadable = store.load() else {
            Issue.record("expected unreadable")
            return
        }
        #expect(throws: HabitStoreError.readOnly) { try store.save(Habits()) }
        #expect(try String(contentsOf: file, encoding: .utf8) == "{ not json")
    }

    @Test func newerFormatIsNeverOverwritten() throws {
        let newer = #"{ "formatVersion": 2, "habits": [] }"#
        try write(newer)
        let store = HabitStore(directory: directory)
        guard case .unreadable = store.load() else {
            Issue.record("expected unreadable")
            return
        }
        #expect(throws: HabitStoreError.readOnly) { try store.save(Habits()) }
        #expect(try String(contentsOf: file, encoding: .utf8) == newer)
    }

    @Test func unknownFieldsInAVersion1FileMakeItUnreadable() throws {
        // Any change to what's written bumps formatVersion, so an extra field means a file v1 didn't write.
        try write(#"{ "formatVersion": 1, "habits": [], "tags": [] }"#)
        guard case .unreadable = HabitStore(directory: directory).load() else {
            Issue.record("expected unreadable")
            return
        }
    }

    /// A one-habit v1 file with one field replaced, for the "v1 never wrote this" tests.
    private func fileWith(addedOn: String = "2026-10-01", days: String = #"["fri", "sun"]"#, checkOffs: String = "[]")
        -> String
    {
        #"{ "formatVersion": 1, "habits": [ { "id": "6F9619FF-8B86-D011-B42D-00CF4FC964FF", "name": "x", "note": "", "addedOn": ""#
            + addedOn + #"", "schedule": [ { "from": "2026-10-01", "days": "# + days + #" } ], "checkOffs": "#
            + checkOffs + " } ] }"
    }

    private func expectUnreadable(_ text: String, sourceLocation: SourceLocation = #_sourceLocation) throws {
        try write(text)
        guard case .unreadable = HabitStore(directory: directory).load() else {
            Issue.record("expected unreadable", sourceLocation: sourceLocation)
            return
        }
    }

    @Test func theFixtureHelperWritesALoadableFile() throws {
        try write(fileWith())
        guard case .loaded = HabitStore(directory: directory).load() else {
            Issue.record("the helper's base file should load")
            return
        }
    }

    @Test func anInvalidDateMakesAFileUnreadable() throws {
        try expectUnreadable(fileWith(addedOn: "2026-02-30"))
    }

    @Test func anUnknownWeekdayMakesAFileUnreadable() throws {
        try expectUnreadable(fileWith(days: #"["funday"]"#))
    }

    @Test func aScheduleWithNoDaysOrRepeatedDaysMakesAFileUnreadable() throws {
        try expectUnreadable(fileWith(days: "[]"))
        try expectUnreadable(fileWith(days: #"["fri", "fri"]"#))
    }

    @Test func repeatedCheckOffsMakeAFileUnreadable() throws {
        try expectUnreadable(fileWith(checkOffs: #"["2026-10-02", "2026-10-02"]"#))
    }

    @Test func duplicateHabitIdsMakeAFileUnreadable() throws {
        let habit =
            #"{ "id": "6F9619FF-8B86-D011-B42D-00CF4FC964FF", "name": "x", "note": "", "addedOn": "2026-10-01", "schedule": [ { "from": "2026-10-01", "days": ["fri"] } ], "checkOffs": [] }"#
        try expectUnreadable(#"{ "formatVersion": 1, "habits": [ "# + habit + ", " + habit + " ] }")
    }

    @Test func saveBeforeLoadIsRefused() throws {
        try write("{ not json")
        #expect(throws: HabitStoreError.readOnly) { try HabitStore(directory: directory).save(Habits()) }
        #expect(try String(contentsOf: file, encoding: .utf8) == "{ not json")
    }

    @Test func saveReplacesTheFileWhole() throws {
        let store = HabitStore(directory: directory)
        _ = store.load()
        var habits = Habits()
        habits.add(HabitDraft(name: String(repeating: "Long name ", count: 4), note: "", days: [1]), today: oct(1))
        try store.save(habits)
        try store.save(Habits())
        #expect(HabitStore(directory: directory).load() == .loaded(Habits()))
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        #expect(leftovers == [HabitStore.fileName])
    }
}
