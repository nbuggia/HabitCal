import CloudKit
import HabitCalKit
import Security
import os

/// The only code that talks to CloudKit (T-039, D-010). For now it reports whether iCloud is
/// available; syncing habits comes next (slices 3 and 4).
@MainActor
final class HabitSync {
    static let containerID = "iCloud.com.muchfiner.HabitCal"
    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HabitCal", category: "HabitSync")

    private let model: AppModel
    private var container: CKContainer?
    private var accountObserver: NSObjectProtocol?

    /// Sync is off when tests run (`allowed` false), when the habits on this Mac can't be read (E.1),
    /// and in any build without the CloudKit entitlement: such a process traps when it touches
    /// `CKContainer`, so it's never created there (Release until T-005's profile exists).
    init(model: AppModel, allowed: Bool, statusOverride: SyncStatus?) {
        self.model = model
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
        let container = CKContainer(identifier: Self.containerID)
        self.container = container
        accountObserver = NotificationCenter.default.addObserver(
            forName: .CKAccountChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshAccountStatus() }
        }
        refreshAccountStatus()
    }

    private func refreshAccountStatus() {
        guard let container else { return }
        Task { @MainActor [weak self] in
            do {
                let status = try await container.accountStatus()
                self?.model.setSyncStatus(Self.syncStatus(for: status))
            } catch {
                Self.log.error("accountStatus failed: \(error.localizedDescription, privacy: .public)")
                self?.model.setSyncStatus(.error(error.localizedDescription))
            }
        }
    }

    private static func syncStatus(for status: CKAccountStatus) -> SyncStatus {
        switch status {
        case .available: return .notSyncedYet
        case .temporarilyUnavailable: return .waiting
        case .noAccount, .restricted, .couldNotDetermine: return .off
        @unknown default: return .off
        }
    }

    private static func hasCloudKitEntitlement() -> Bool {
        guard let task = SecTaskCreateFromSelf(nil),
            let services = SecTaskCopyValueForEntitlement(task, "com.apple.developer.icloud-services" as CFString, nil)
                as? [String]
        else { return false }
        return services.contains("CloudKit")
    }
}
