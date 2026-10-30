import Foundation

public enum HabitStoreError: Error, Equatable {
    /// The file couldn't be read, or no load has happened yet, so saving could destroy data (D-004).
    case readOnly
}

/// The only reader and writer of `habits.json` (D-006). The JSON shape lives in the private types
/// below, not on the model, so renaming a Swift property can never silently change the format.
public final class HabitStore {
    public static let fileName = "habits.json"
    /// Any change to what is written bumps this. An older build then sees a newer version, treats the
    /// file as unreadable, and never saves over it, so it can't drop fields it doesn't know (D-004).
    public static let formatVersion = 1

    public enum LoadResult: Equatable {
        case loaded(Habits)
        /// No file yet.
        case empty
        case unreadable(String)
    }

    private let directory: URL
    /// Saving is allowed only after a load that came back `.loaded` or `.empty` (FM-003).
    private var canSave = false

    public init(directory: URL) {
        self.directory = directory
    }

    public var fileURL: URL {
        directory.appendingPathComponent(Self.fileName)
    }

    public func load() -> LoadResult {
        canSave = false
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch CocoaError.fileReadNoSuchFile {
            canSave = true
            return .empty
        } catch {
            return .unreadable(error.localizedDescription)
        }
        do {
            try FileV1.checkKeys(data)
            let file = try JSONDecoder().decode(FileV1.self, from: data)
            guard file.formatVersion == Self.formatVersion else {
                return .unreadable("format version \(file.formatVersion) is newer than this version of HabitCal")
            }
            let list = try file.habits.map { try $0.habit() }
            guard Set(list.map(\.id)).count == list.count else {
                throw FormatError(description: "duplicate habit ids")
            }
            let habits = Habits(list)
            canSave = true
            return .loaded(habits)
        } catch {
            return .unreadable(String(describing: error))
        }
    }

    /// Writes the whole file atomically: a temporary file, then a rename, so a crash leaves the old
    /// file intact.
    public func save(_ habits: Habits) throws {
        guard canSave else { throw HabitStoreError.readOnly }
        let file = FileV1(formatVersion: Self.formatVersion, habits: habits.all.map(HabitV1.init))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(file)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
}

// MARK: - Format version 1 (docs/engineering/CONTRACTS.md, "Saved habit data")

private struct FormatError: Error, CustomStringConvertible {
    let description: String
}

private let weekdayNames = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]

private func day(_ iso: String) throws -> Day {
    guard let day = Day(iso: iso) else { throw FormatError(description: "invalid date \(iso)") }
    return day
}

private struct FileV1: Codable {
    let formatVersion: Int
    let habits: [HabitV1]

    static let keys: Set<String> = ["formatVersion", "habits"]

    /// A version-1 file has exactly the keys version 1 writes. Anything else was written by a
    /// different version, so the file is treated as unreadable rather than half-read.
    static func checkKeys(_ data: Data) throws {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FormatError(description: "not a JSON object")
        }
        guard (root["formatVersion"] as? Int) == HabitStore.formatVersion else { return }
        try expect(root, keys)
        for habit in root["habits"] as? [[String: Any]] ?? [] {
            try expect(habit, HabitV1.keys)
            for entry in habit["schedule"] as? [[String: Any]] ?? [] {
                try expect(entry, ScheduleEntryV1.keys)
            }
        }
    }

    private static func expect(_ object: [String: Any], _ keys: Set<String>) throws {
        guard Set(object.keys) == keys else {
            throw FormatError(description: "unexpected fields \(Set(object.keys).symmetricDifference(keys).sorted())")
        }
    }
}

private struct HabitV1: Codable {
    let id: UUID
    let name: String
    let note: String
    let addedOn: String
    let schedule: [ScheduleEntryV1]
    let checkOffs: [String]

    static let keys: Set<String> = ["id", "name", "note", "addedOn", "schedule", "checkOffs"]

    init(_ habit: Habit) {
        id = habit.id
        name = habit.name
        note = habit.note
        addedOn = habit.addedOn.iso
        schedule = habit.schedule.map(ScheduleEntryV1.init)
        checkOffs = habit.checkOffs.sorted().map(\.iso)
    }

    func habit() throws -> Habit {
        guard !schedule.isEmpty else { throw FormatError(description: "habit \(id) has no schedule") }
        guard Set(checkOffs).count == checkOffs.count else {
            throw FormatError(description: "habit \(id) has duplicate check-offs")
        }
        return Habit(
            id: id, name: name, note: note, addedOn: try day(addedOn), schedule: try schedule.map { try $0.entry() },
            checkOffs: Set(try checkOffs.map(day)))
    }
}

private struct ScheduleEntryV1: Codable {
    let from: String
    let days: [String]

    static let keys: Set<String> = ["from", "days"]

    init(_ entry: ScheduleEntry) {
        from = entry.from.iso
        days = entry.days.sorted().map { weekdayNames[$0 - 1] }
    }

    func entry() throws -> ScheduleEntry {
        // Version 1 writes 1–7 distinct weekdays; anything else wasn't written by it.
        guard !days.isEmpty, Set(days).count == days.count else {
            throw FormatError(description: "invalid schedule days \(days)")
        }
        let weekdays = try days.map { name in
            guard let index = weekdayNames.firstIndex(of: name) else {
                throw FormatError(description: "invalid weekday \(name)")
            }
            return index + 1
        }
        return ScheduleEntry(from: try day(from), days: Set(weekdays))
    }
}
