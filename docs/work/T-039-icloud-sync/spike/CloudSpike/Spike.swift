import CloudKit
import SwiftUI

// Throwaway T-039 spike: can a sandboxed HabitCal reach CloudKit with no network entitlement, and how
// does it behave without an iCloud account? Runs every check on launch, shows the log, and appends it
// to Library/Containers/<bundle id>/Data/spike.log (or the path passed as the first argument).

@main
struct SpikeApp: App {
    @State private var log = Log()

    var body: some Scene {
        WindowGroup("CloudSpike") {
            ScrollView {
                Text(log.text).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading).padding()
            }
            .frame(width: 560, height: 420)
            .task { await runChecks(log) }
        }
    }
}

@MainActor @Observable
final class Log {
    var text = ""
    private let url: URL = {
        if CommandLine.arguments.count > 1 { return URL(fileURLWithPath: CommandLine.arguments[1]) }
        return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("spike.log")
    }()

    func add(_ line: String) {
        let stamped = "\(Date().formatted(date: .omitted, time: .standard))  \(line)\n"
        text += stamped
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile(); handle.write(Data(stamped.utf8)); try? handle.close()
        } else {
            try? Data(stamped.utf8).write(to: url)
        }
        print(stamped, terminator: "")
    }
}

@MainActor
func runChecks(_ log: Log) async {
    let container = CKContainer(identifier: "iCloud.com.muchfiner.HabitCal")
    let entitlements = ["com.apple.security.network.client"]
        .map { "\($0)=\(hasEntitlement($0))" }.joined(separator: " ")
    log.add("Q2 entitlements: \(entitlements); log at \(NSHomeDirectory())/spike.log")

    // Q3: account status, quietly.
    do {
        let status = try await container.accountStatus()
        log.add("Q3 accountStatus: \(describe(status))")
        if status != .available {
            log.add("No usable account: stopping here (expected when signed out or iCloud is off for the app).")
            return
        }
        let userID = try await container.userRecordID()
        log.add("Q3 userRecordID: \(userID.recordName.prefix(12))…")
    } catch {
        log.add("Q3 accountStatus FAILED: \(describeError(error))")
        return
    }

    // Q1/Q2: a round trip in the private database, in a custom zone (what CKSyncEngine uses).
    let db = container.privateCloudDatabase
    let zone = CKRecordZone(zoneName: "SpikeZone")
    do {
        _ = try await db.modifyRecordZones(saving: [zone], deleting: [])
        log.add("Q1 zone saved")
        let record = CKRecord(recordType: "SpikeHabit", recordID: CKRecord.ID(recordName: "spike-1", zoneID: zone.zoneID))
        record["name"] = "Push-ups" as CKRecordValue
        record["checkOffs"] = ["2026-10-30", "2026-10-31"] as CKRecordValue
        let saved = try await db.modifyRecords(saving: [record], deleting: [], savePolicy: .allKeys)
        log.add("Q1 record saved: \(saved.saveResults.count) result(s), \(describeResults(saved.saveResults))")
        let fetched = try await db.record(for: record.recordID)
        log.add("Q1 record fetched back: name=\(fetched["name"] as? String ?? "nil") checkOffs=\(fetched["checkOffs"] as? [String] ?? [])")
        _ = try await db.modifyRecordZones(saving: [], deleting: [zone.zoneID])
        log.add("Q1 zone deleted. CloudKit round trip OK.")
    } catch {
        log.add("Q1 round trip FAILED: \(describeError(error))")
    }

    // Q4: CKSyncEngine starts (macOS 14+), with no saved state.
    if #available(macOS 14.0, *) {
        let engine = CKSyncEngine(CKSyncEngine.Configuration(database: db, stateSerialization: nil, delegate: EngineDelegate(log: log)))
        do {
            try await engine.fetchChanges()
            log.add("Q4 CKSyncEngine fetchChanges OK")
        } catch {
            log.add("Q4 CKSyncEngine fetchChanges FAILED: \(describeError(error))")
        }
        _ = engine
    }
    log.add("Done.")
}

@available(macOS 14.0, *)
final class EngineDelegate: CKSyncEngineDelegate, @unchecked Sendable {
    let log: Log
    init(log: Log) { self.log = log }
    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        let name = String(describing: event).prefix(80)
        await MainActor.run { log.add("Q4 event: \(name)") }
    }
    func nextRecordZoneChangeBatch(_ context: CKSyncEngine.SendChangesContext, syncEngine: CKSyncEngine) async -> CKSyncEngine.RecordZoneChangeBatch? { nil }
}

func describe(_ status: CKAccountStatus) -> String {
    switch status {
    case .available: return "available"
    case .noAccount: return "noAccount"
    case .restricted: return "restricted"
    case .couldNotDetermine: return "couldNotDetermine"
    case .temporarilyUnavailable: return "temporarilyUnavailable"
    @unknown default: return "unknown(\(status.rawValue))"
    }
}

func describeError(_ error: Error) -> String {
    if let ck = error as? CKError { return "CKError \(ck.code.rawValue) (\(ck.code)): \(ck.localizedDescription)" }
    return "\(error)"
}

func describeResults(_ results: [CKRecord.ID: Result<CKRecord, Error>]) -> String {
    results.values.map { if case .failure(let e) = $0 { return describeError(e) } else { return "ok" } }.joined(separator: ", ")
}

func hasEntitlement(_ key: String) -> Bool {
    guard let task = SecTaskCreateFromSelf(nil) else { return false }
    return SecTaskCopyValueForEntitlement(task, key as CFString, nil) != nil
}
