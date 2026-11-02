import AppKit
import CloudKit
import HabitCalKit
import Security
import os

/// The only code that talks to CloudKit (T-039, D-010). It keeps habits in the user's private iCloud
/// database, one `Habit` record per habit in the `Habits` zone, through `CKSyncEngine`. It translates
/// engine events into `SyncPolicy` and `AppModel` calls; the merge rules live in HabitCalKit.
@MainActor
final class HabitSync: CKSyncEngineDelegate {
    static let containerID = "iCloud.com.muchfiner.HabitCal"
    private static let recordType = "Habit"
    private static let zoneID = CKRecordZone.ID(zoneName: "Habits")
    /// The 60 s fetch backs up CloudKit's pushes, which aren't proven to arrive (design §3). Fetches
    /// closer together than this are skipped.
    private static let fetchInterval: TimeInterval = 60
    private static let minimumFetchGap: TimeInterval = 50
    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HabitCal", category: "HabitSync")

    private let model: AppModel
    private let stateURL: URL
    private var state = SyncState()
    private var container: CKContainer?
    private var engine: CKSyncEngine?
    private var accountObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var timer: Timer?
    private var lastFetch: Date = .distantPast

    /// Sync is off when tests run (`allowed` false), when the habits on this Mac can't be read (E.1),
    /// and in any build without the CloudKit entitlement: such a process traps when it touches
    /// `CKContainer`, so it's never created there (Release until T-005's profile exists).
    init(model: AppModel, allowed: Bool, statusOverride: SyncStatus?, directory: URL) {
        self.model = model
        stateURL = directory.appendingPathComponent("sync-state.json")
        if let statusOverride {
            model.setSyncStatus(statusOverride)
            return
        }
        if case .unreadable = model.dataState {
            model.setSyncStatus(.error("HabitCal couldn't read the habits on this Mac."))
            return
        }
        guard allowed, Self.hasCloudKitEntitlement() else {
            model.setSyncStatus(.off)
            return
        }
        start()
    }

    /// Pushes reach the sync engine only once the app is registered for remote notifications.
    func didFinishLaunching() {
        guard engine != nil else { return }
        NSApplication.shared.registerForRemoteNotifications()
    }

    private func start() {
        let container = CKContainer(identifier: Self.containerID)
        self.container = container
        state = loadState()
        if SyncPolicy.atStart(updateNeeded: state.updateNeeded) == .refetchEverything {
            state.engineState = nil
            state.systemFields = [:]
            state.updateNeeded = false
            saveState()
        }
        let engine = CKSyncEngine(
            CKSyncEngine.Configuration(
                database: container.privateCloudDatabase, stateSerialization: state.engineState, delegate: self))
        self.engine = engine
        if state.engineState == nil {
            engine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: Self.zoneID))])
        }
        if state.firstSyncDone {
            changed(SyncPolicy.unsent(in: model.habits, since: state.lastSentAt))
        }
        model.habitsDidChange = { [weak self] ids in self?.changed(ids) }
        model.syncNow = { [weak self] in self?.syncNow() }
        accountObserver = NotificationCenter.default.addObserver(
            forName: .CKAccountChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshAccountStatus() }
        }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.fetchSoon() }
        }
        timer = Timer.scheduledTimer(withTimeInterval: Self.fetchInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.fetchSoon() }
        }
        refreshAccountStatus()
    }

    // MARK: Triggers

    /// Habits changed on this Mac: queue them for sending. They're held until the first sync is done
    /// (`SyncPolicy.answersSendBatch`).
    func changed(_ ids: Set<UUID>) {
        guard let engine else { return }
        engine.state.add(pendingRecordZoneChanges: ids.map { .saveRecord(Self.recordID($0)) })
    }

    /// Fetches unless one ran less than 50 s ago: wake and the 60 s timer (B.2, B.3).
    func fetchSoon() {
        guard let engine, Date().timeIntervalSince(lastFetch) >= Self.minimumFetchGap else { return }
        lastFetch = Date()
        detached(engine) { try await $0.fetchChanges() }
    }

    /// Runs an engine call outside any delegate callback. CloudKit traps on an engine call awaited from
    /// inside a callback that calls back into the delegate, and a plain `Task` started in a callback
    /// counts as inside it, so engine calls always start detached.
    private func detached(
        _ engine: CKSyncEngine, then done: (@MainActor (HabitSync) -> Void)? = nil,
        _ call: @escaping @Sendable (CKSyncEngine) async throws -> Void
    ) {
        Task.detached { [weak self] in
            do {
                try await call(engine)
                await MainActor.run { if let self { done?(self) } }
            } catch {
                await MainActor.run { self?.report(error) }
            }
        }
    }

    /// Sync Now (B.22): fetch, then send, showing "Syncing…" and then the result.
    func syncNow() {
        guard let engine, model.syncStatus.allowsSyncNow else { return }
        model.setSyncStatus(.syncing)
        lastFetch = Date()
        let send = SyncPolicy.answersSendBatch(firstSyncDone: state.firstSyncDone, updateNeeded: state.updateNeeded)
        detached(
            engine, then: { $0.markSynced() },
            { engine in
                try await engine.fetchChanges()
                if send { try await engine.sendChanges() }
            })
    }

    // MARK: CKSyncEngineDelegate

    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        switch event {
        case .stateUpdate(let update):
            state.engineState = update.stateSerialization
            saveState()
        case .accountChange(let change):
            Self.log.info("account change: \(String(describing: change.changeType), privacy: .public)")
            accountChanged(change.changeType)
        case .fetchedDatabaseChanges(let changes):
            if changes.deletions.contains(where: { $0.zoneID == Self.zoneID }) { zoneReset() }
        case .fetchedRecordZoneChanges(let changes):
            receive(changes.modifications.map(\.record))
        case .sentRecordZoneChanges(let sent):
            for record in sent.savedRecords { cacheSystemFields(record) }
            handleFailedSaves(sent.failedRecordSaves)
        case .willFetchChanges:
            if !state.firstSyncDone { model.setSyncStatus(.syncing) }
        case .didFetchChanges:
            let next = SyncPolicy.afterFetchFinished(firstSyncDone: state.firstSyncDone)
            if next.markFirstSyncDone {
                // Batches merge as they arrive; this pass queues every habit only this Mac has,
                // including all of them when iCloud was empty and nothing arrived (B.7).
                changed(model.applyRemote([], firstSyncDone: false))
                state.firstSyncDone = true
                saveState()
            }
            markSynced()
            if next.sendNow {
                detached(syncEngine) { try await $0.sendChanges() }
            }
        case .didSendChanges:
            if syncEngine.state.pendingRecordZoneChanges.isEmpty {
                state.lastSentAt = Date()
                saveState()
            }
            markSynced()
        default:
            break
        }
    }

    func nextRecordZoneChangeBatch(_ context: CKSyncEngine.SendChangesContext, syncEngine: CKSyncEngine) async
        -> CKSyncEngine.RecordZoneChangeBatch?
    {
        guard SyncPolicy.answersSendBatch(firstSyncDone: state.firstSyncDone, updateNeeded: state.updateNeeded) else {
            return nil
        }
        let pending = syncEngine.state.pendingRecordZoneChanges.filter { context.options.scope.contains($0) }
        var records: [CKRecord.ID: CKRecord] = [:]
        var gone: [CKSyncEngine.PendingRecordZoneChange] = []
        for change in pending {
            guard case .saveRecord(let recordID) = change else { continue }
            // A habit merged into another by name at the first sync no longer exists under its own ID.
            guard let id = UUID(uuidString: recordID.recordName), let habit = model.record(id),
                let record = makeRecord(for: habit)
            else {
                gone.append(change)
                continue
            }
            records[recordID] = record
        }
        syncEngine.state.remove(pendingRecordZoneChanges: gone)
        let provided = records
        return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: pending.filter { !gone.contains($0) }) {
            provided[$0]
        }
    }

    // MARK: Records

    private static func recordID(_ id: UUID) -> CKRecord.ID {
        CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
    }

    /// Starts from the record's last known system fields, so CloudKit accepts the save as a change to
    /// its current version (design §15 row 1); a habit never sent gets a new record.
    private func makeRecord(for habit: Habit) -> CKRecord? {
        guard let payload = try? HabitCodec.encode(habit) else { return nil }
        let recordID = Self.recordID(habit.id)
        let record = cachedRecord(recordID) ?? CKRecord(recordType: Self.recordType, recordID: recordID)
        record["formatVersion"] = HabitCodec.formatVersion as NSNumber
        record["payload"] = payload as NSData
        return record
    }

    private func cachedRecord(_ recordID: CKRecord.ID) -> CKRecord? {
        guard let data = state.systemFields[recordID.recordName],
            let coder = try? NSKeyedUnarchiver(forReadingFrom: data)
        else { return nil }
        coder.requiresSecureCoding = true
        defer { coder.finishDecoding() }
        return CKRecord(coder: coder)
    }

    private func cacheSystemFields(_ record: CKRecord) {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        record.encodeSystemFields(with: coder)
        coder.finishEncoding()
        state.systemFields[record.recordID.recordName] = coder.encodedData
    }

    private func decode(_ record: CKRecord) -> Habit? {
        guard record.recordType == Self.recordType, let payload = record["payload"] as? Data,
            let version = (record["formatVersion"] as? NSNumber)?.intValue
        else { return nil }
        do {
            return try HabitCodec.decode(payload, formatVersion: version)
        } catch HabitCodec.Error.newerFormat {
            // Another Mac runs a newer HabitCal: stop sending, say so, and fetch everything again once
            // this Mac is updated (E.6).
            state.updateNeeded = true
            saveState()
            model.setSyncStatus(.updateNeeded)
            return nil
        } catch {
            // Skipped whole, never half-applied (E.9).
            Self.log.error(
                "skipped record \(record.recordID.recordName, privacy: .public): \(String(describing: error), privacy: .public)"
            )
            return nil
        }
    }

    /// Fetched records: merged and saved before returning, since the engine moves past them next.
    private func receive(_ records: [CKRecord]) {
        for record in records { cacheSystemFields(record) }
        saveState()
        let habits = records.compactMap(decode)
        guard !habits.isEmpty else { return }
        let toSend = model.applyRemote(habits, firstSyncDone: state.firstSyncDone)
        changed(toSend)
    }

    private func handleFailedSaves(_ failures: [CKSyncEngine.Event.SentRecordZoneChanges.FailedRecordSave]) {
        guard let engine else { return }
        for failure in failures {
            let recordID = failure.record.recordID
            switch failure.error.code {
            case .serverRecordChanged:
                if let server = failure.error.serverRecord {
                    cacheSystemFields(server)
                    if let habit = decode(server), let id = model.resolveConflict(server: habit) {
                        changed([id])
                    }
                }
            case .zoneNotFound, .userDeletedZone:
                zoneReset()
            case .unknownItem:
                // The cached system fields name a record iCloud no longer has: send it as new.
                state.systemFields[recordID.recordName] = nil
                engine.state.add(pendingRecordZoneChanges: [.saveRecord(recordID)])
            default:
                report(failure.error)
            }
        }
        saveState()
    }

    // MARK: Status

    private func markSynced() {
        guard !state.updateNeeded else {
            model.setSyncStatus(.updateNeeded)
            return
        }
        state.lastSynced = Date()
        saveState()
        model.setSyncStatus(.synced(state.lastSynced ?? Date()))
    }

    private func report(_ error: Error) {
        Self.log.error("sync error: \(String(describing: error), privacy: .public)")
        model.setSyncStatus(SyncPolicy.status(for: Self.failure(error)))
    }

    private static func failure(_ error: Error) -> SyncPolicy.Failure {
        guard let error = error as? CKError else { return .other(error.localizedDescription) }
        switch error.code {
        case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy:
            return .network
        case .quotaExceeded: return .quota
        case .notAuthenticated: return .notSignedIn
        default: return .other(error.localizedDescription)
        }
    }

    // MARK: Recovery

    /// The zone is gone from iCloud (the user deleted HabitCal's data, or it was reset): recreate it and
    /// send every record again, deleted habits included (E.4).
    private func zoneReset() {
        guard let engine else { return }
        state.systemFields = [:]
        saveState()
        engine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: Self.zoneID))])
        changed(SyncPolicy.afterZoneReset(model.habits))
    }

    /// The engine resets its own state on an account change; this resets HabitSync's. Signing in or
    /// switching starts a first sync into that account, merging this Mac's habits in; the old account's
    /// deleted habits aren't sent there (the first-sync merge drops them). Signing out keeps every habit
    /// here (E.2, E.3).
    private func accountChanged(_ change: CKSyncEngine.Event.AccountChange.ChangeType) {
        let kind: SyncPolicy.AccountChange
        switch change {
        case .signIn:
            // The first launch reports a sign-in too; with no first sync yet there's nothing to reset.
            guard state.firstSyncDone else {
                refreshAccountStatus()
                return
            }
            kind = .signIn
        case .switchAccounts: kind = .switchAccounts
        case .signOut: kind = .signOut
        @unknown default: return
        }
        let decision = SyncPolicy.accountChanged(kind)
        if decision.resetState {
            let engineState = state.engineState
            state = SyncState()
            state.engineState = engineState
            saveState()
            if kind != .signOut {
                engine?.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: Self.zoneID))])
            }
        }
        model.setSyncStatus(decision.status)
    }

    private func refreshAccountStatus() {
        guard let container else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                switch try await container.accountStatus() {
                case .available:
                    if let lastSynced = self.state.lastSynced {
                        self.model.setSyncStatus(.synced(lastSynced))
                    } else {
                        self.model.setSyncStatus(.notSyncedYet)
                    }
                    self.fetchSoon()
                case .temporarilyUnavailable: self.model.setSyncStatus(.waiting)
                case .noAccount, .restricted, .couldNotDetermine: self.model.setSyncStatus(.off)
                @unknown default: self.model.setSyncStatus(.off)
                }
            } catch {
                self.report(error)
            }
        }
    }

    private static func hasCloudKitEntitlement() -> Bool {
        guard let task = SecTaskCreateFromSelf(nil),
            let services = SecTaskCopyValueForEntitlement(task, "com.apple.developer.icloud-services" as CFString, nil)
                as? [String]
        else { return false }
        return services.contains("CloudKit")
    }

    // MARK: sync-state.json

    private func loadState() -> SyncState {
        // An unreadable state file is dropped: the next start is a first sync, which loses nothing.
        guard let data = try? Data(contentsOf: stateURL),
            let loaded = try? JSONDecoder().decode(SyncState.self, from: data)
        else { return SyncState() }
        return loaded
    }

    private func saveState() {
        do {
            try FileManager.default.createDirectory(
                at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(state).write(to: stateURL, options: .atomic)
        } catch {
            Self.log.error("saving sync state failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

/// What HabitSync keeps between launches, in `sync-state.json` next to `habits.json`. Only HabitSync
/// reads or writes it.
private struct SyncState: Codable {
    var engineState: CKSyncEngine.State.Serialization?
    var firstSyncDone = false
    /// Each record's system fields from its last known server version, by record name.
    var systemFields: [String: Data] = [:]
    var lastSynced: Date?
    var lastSentAt: Date?
    /// A record was skipped as written by a newer HabitCal (E.6).
    var updateNeeded = false
}
