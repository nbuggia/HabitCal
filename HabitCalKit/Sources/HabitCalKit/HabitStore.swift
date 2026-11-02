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
    /// Version 2 (T-039) adds change times, unchecks, and deleted habits; version 1 still loads.
    public static let formatVersion = 2

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
            let habits = try Self.decodeFile(data)
            canSave = true
            return .loaded(habits)
        } catch {
            return .unreadable(String(describing: error))
        }
    }

    /// Reads a version 1 or 2 file. Anything else, or fields and values neither version writes, is an
    /// error, so the file is never half-read (D-004).
    static func decodeFile(_ data: Data) throws -> Habits {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FormatError(description: "not a JSON object")
        }
        let version = root["formatVersion"] as? Int
        let list: [Habit]
        switch version {
        case 1:
            try FileV1.checkKeys(root)
            let file = try JSONDecoder().decode(FileV1.self, from: data)
            // Version 1 has no change times or creation moments: keep its order with creation moments
            // a millisecond apart, earlier than any real one (T-039).
            list = try file.habits.enumerated().map { offset, habit in
                var migrated = try habit.habit()
                migrated.createdAt = Habits.stamp(Date.distantPast.addingTimeInterval(Double(offset) * 0.001))
                return migrated
            }
        case 2:
            try expect(root, ["formatVersion", "habits"])
            for habit in root["habits"] as? [[String: Any]] ?? [] { try HabitV2.checkKeys(habit) }
            let file = try JSONDecoder().decode(FileV2.self, from: data)
            list = try file.habits.map { try $0.habit() }
        default:
            throw FormatError(
                description:
                    "format version \(version.map(String.init) ?? "missing") is newer than this version of HabitCal")
        }
        guard Set(list.map(\.id)).count == list.count else { throw FormatError(description: "duplicate habit ids") }
        return Habits(list)
    }

    /// An export (T-035): the shown habits in the saved-data format, so any HabitCal that reads its own
    /// file reads an export too. Deleted habits are left out: an import adds new habits anyway (T-039).
    public static func exportData(_ habits: Habits) throws -> Data {
        try HabitCodec.encoder.encode(FileV2(formatVersion: formatVersion, habits: habits.all.map(HabitV2.init)))
    }

    /// Why a file can't be imported (T-035 E.3–E.5).
    public enum ImportError: Error, Equatable {
        /// The file couldn't be opened; macOS's reason.
        case cantOpen(String)
        /// Not JSON, other fields, invalid values, no format version, or over `importLimit`.
        case notHabitCal(String)
        /// Written by a newer HabitCal.
        case newerFormat(Int)
    }

    /// The largest file accepted for import. Years of daily check-offs for dozens of habits stay well
    /// under 1 MB, so anything bigger isn't a HabitCal export (T-035 Limits).
    public static let importLimit = 10 * 1024 * 1024

    /// Reads a habits file to import: any format HabitCal loads as its own data, through the same
    /// decoder (B.9). The size is checked before the file is read.
    public static func importHabits(from url: URL) throws -> Habits {
        let size: Int
        do {
            size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        } catch {
            throw ImportError.cantOpen(error.localizedDescription)
        }
        guard size <= importLimit else { throw ImportError.notHabitCal("larger than \(importLimit) bytes") }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ImportError.cantOpen(error.localizedDescription)
        }
        if let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let version = root["formatVersion"] as? Int, version > formatVersion
        {
            throw ImportError.newerFormat(version)
        }
        do {
            return try decodeFile(data)
        } catch {
            throw ImportError.notHabitCal(String(describing: error))
        }
    }

    /// Writes the whole file atomically: a temporary file, then a rename, so a crash leaves the old
    /// file intact.
    public func save(_ habits: Habits) throws {
        guard canSave else { throw HabitStoreError.readOnly }
        let file = FileV2(formatVersion: Self.formatVersion, habits: habits.records.map(HabitV2.init))
        let data = try HabitCodec.encoder.encode(file)
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

private struct FileV1: Decodable {
    let formatVersion: Int
    let habits: [HabitV1]

    static let keys: Set<String> = ["formatVersion", "habits"]

    /// A version-1 file has exactly the keys version 1 writes. Anything else was written by a
    /// different version, so the file is treated as unreadable rather than half-read.
    static func checkKeys(_ root: [String: Any]) throws {
        try expect(root, keys)
        for habit in root["habits"] as? [[String: Any]] ?? [] {
            try expect(habit, HabitV1.keys)
            for entry in habit["schedule"] as? [[String: Any]] ?? [] {
                try expect(entry, ScheduleEntryV1.keys)
            }
        }
    }
}

/// Exactly `keys`, or a version that writes something else wrote it.
private func expect(_ object: [String: Any], _ keys: Set<String>, optional: Set<String> = []) throws {
    let found = Set(object.keys)
    guard keys.isSubset(of: found), found.isSubset(of: keys.union(optional)) else {
        throw FormatError(
            description: "unexpected fields \(found.symmetricDifference(keys).subtracting(optional).sorted())")
    }
}

private struct HabitV1: Decodable {
    let id: UUID
    let name: String
    let note: String
    let addedOn: String
    let schedule: [ScheduleEntryV1]
    let checkOffs: [String]

    static let keys: Set<String> = ["id", "name", "note", "addedOn", "schedule", "checkOffs"]

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

private struct ScheduleEntryV1: Decodable {
    let from: String
    let days: [String]

    static let keys: Set<String> = ["from", "days"]

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

// MARK: - Format version 2 (docs/engineering/CONTRACTS.md, "Saved habit data"; T-039)

/// One habit as JSON, shared by `habits.json` and the iCloud record's payload (T-039): one format, one
/// codec.
public enum HabitCodec {
    public enum Error: Swift.Error, Equatable {
        /// Written by a newer HabitCal (T-039 E.6).
        case newerFormat(Int)
        case invalid(String)
    }

    /// The payload format version this build writes and the newest it reads.
    public static let formatVersion = HabitStore.formatVersion

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    public static func encode(_ habit: Habit) throws -> Data {
        try encoder.encode(HabitV2(habit))
    }

    /// Decodes one habit's payload, refusing one from a newer format or with anything version 2
    /// doesn't write, so it's applied whole or not at all (T-039 E.6, E.9).
    public static func decode(_ data: Data, formatVersion: Int) throws -> Habit {
        guard formatVersion <= Self.formatVersion else { throw Error.newerFormat(formatVersion) }
        guard formatVersion == 2 else { throw Error.invalid("payload format version \(formatVersion)") }
        do {
            guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw FormatError(description: "not a JSON object")
            }
            try HabitV2.checkKeys(object)
            return try JSONDecoder().decode(HabitV2.self, from: data).habit()
        } catch let error as Error {
            throw error
        } catch {
            throw Error.invalid(String(describing: error))
        }
    }
}

private let timeStyle = Date.ISO8601FormatStyle(includingFractionalSeconds: true, timeZone: .gmt)
private let wholeSecondsStyle = Date.ISO8601FormatStyle(timeZone: .gmt)

private func time(_ text: String) throws -> Date {
    do { return Habits.stamp(try Date(text, strategy: timeStyle)) } catch {
        throw FormatError(description: "invalid time \(text)")
    }
}

/// "2026-10-26T07:33:20.001Z". The milliseconds are written from the rounded count, not by the
/// formatter, which truncates: 20.001 is stored as 20.000999…, and would be written as 20.000.
private func timeText(_ date: Date) -> String {
    let ms = Int64((date.timeIntervalSince1970 * 1000).rounded())
    let seconds = ms >= 0 ? ms / 1000 : (ms - 999) / 1000
    let whole = wholeSecondsStyle.format(Date(timeIntervalSince1970: Double(seconds)))
    return whole.dropLast() + String(format: ".%03lldZ", ms - seconds * 1000)
}

private struct FileV2: Codable {
    let formatVersion: Int
    let habits: [HabitV2]
}

private struct HabitV2: Codable {
    let id: UUID
    let addedOn: String
    let createdAt: String
    let deletedAt: String?
    let details: DetailsV2
    let checks: [CheckV2]

    static let keys: Set<String> = ["id", "addedOn", "createdAt", "details", "checks"]

    static func checkKeys(_ object: [String: Any]) throws {
        try expect(object, keys, optional: ["deletedAt"])
        guard let details = object["details"] as? [String: Any] else {
            throw FormatError(description: "missing details")
        }
        try expect(details, ["name", "note", "schedule"], optional: ["changedAt"])
        for entry in details["schedule"] as? [[String: Any]] ?? [] { try expect(entry, ["from", "days"]) }
        for check in object["checks"] as? [[String: Any]] ?? [] {
            try expect(check, ["day", "done"], optional: ["changedAt"])
        }
    }

    init(_ habit: Habit) {
        id = habit.id
        addedOn = habit.addedOn.iso
        createdAt = timeText(habit.createdAt)
        deletedAt = habit.deletedAt.map(timeText)
        details = DetailsV2(habit.details)
        checks = habit.checks.sorted { $0.key < $1.key }.map {
            CheckV2(day: $0.key.iso, done: $0.value.done, changedAt: $0.value.changedAt.map(timeText))
        }
    }

    func habit() throws -> Habit {
        let schedule = try details.schedule.map { try $0.entry() }
        guard !schedule.isEmpty else { throw FormatError(description: "habit \(id) has no schedule") }
        guard Set(schedule.map(\.from)).count == schedule.count else {
            throw FormatError(description: "habit \(id) has two schedule entries on one day")
        }
        var byDay: [Day: Check] = [:]
        for check in checks {
            let day = try day(check.day)
            guard byDay[day] == nil else {
                throw FormatError(description: "habit \(id) has two checks on \(check.day)")
            }
            byDay[day] = Check(done: check.done, changedAt: try check.changedAt.map(time))
        }
        return Habit(
            id: id,
            details: HabitDetails(
                name: details.name, note: details.note, schedule: schedule,
                changedAt: try details.changedAt.map(time)),
            addedOn: try day(addedOn), createdAt: try time(createdAt), deletedAt: try deletedAt.map(time),
            checks: byDay)
    }
}

private struct DetailsV2: Codable {
    let name: String
    let note: String
    let schedule: [ScheduleEntryV2]
    let changedAt: String?

    init(_ details: HabitDetails) {
        name = details.name
        note = details.note
        schedule = details.schedule.map(ScheduleEntryV2.init)
        changedAt = details.changedAt.map(timeText)
    }
}

private struct ScheduleEntryV2: Codable {
    let from: String
    let days: [String]

    init(_ entry: ScheduleEntry) {
        from = entry.from.iso
        days = entry.days.sorted().map { weekdayNames[$0 - 1] }
    }

    /// Version 2 writes 0–7 distinct weekdays: an entry before today can have none (T-039 B.8a).
    func entry() throws -> ScheduleEntry {
        guard Set(days).count == days.count else { throw FormatError(description: "invalid schedule days \(days)") }
        let weekdays = try days.map { name in
            guard let index = weekdayNames.firstIndex(of: name) else {
                throw FormatError(description: "invalid weekday \(name)")
            }
            return index + 1
        }
        return ScheduleEntry(from: try day(from), days: Set(weekdays))
    }
}

private struct CheckV2: Codable {
    let day: String
    let done: Bool
    let changedAt: String?
}
