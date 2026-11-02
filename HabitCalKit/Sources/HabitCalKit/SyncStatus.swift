import Foundation

/// What Settings says about iCloud sync (T-039 spec, section 5).
public enum SyncStatus: Equatable, Sendable {
    /// iCloud is available, and nothing has synced yet.
    case notSyncedYet
    case syncing
    case synced(Date)
    /// Not signed into iCloud, iCloud unavailable to HabitCal, or a build without iCloud.
    case off
    /// Offline, or iCloud can't be reached.
    case waiting
    case full
    /// Another Mac wrote habits in a newer format (E.6).
    case updateNeeded
    /// Any other error, with macOS's reason.
    case error(String)

    /// Sync Now is offered whenever iCloud can be asked, and isn't already syncing (B.22).
    public var allowsSyncNow: Bool {
        switch self {
        case .notSyncedYet, .synced, .waiting, .full, .error: return true
        case .syncing, .off, .updateNeeded: return false
        }
    }

    /// The Debug-only `-HabitCalSyncStatus` argument's names, so UI tests can show any state.
    public init?(debugName: String) {
        switch debugName {
        case "notSyncedYet": self = .notSyncedYet
        case "syncing": self = .syncing
        case "synced": self = .synced(Date(timeIntervalSince1970: 1_793_007_660))
        case "off": self = .off
        case "waiting": self = .waiting
        case "full": self = .full
        case "updateNeeded": self = .updateNeeded
        case "error": self = .error("The request timed out.")
        default: return nil
        }
    }
}

/// The status line's text, and what VoiceOver reads (E.11).
public struct SyncStatusLabel: Equatable, Sendable {
    public let title: String
    public let detail: String?

    public var spoken: String {
        guard let detail else { return "iCloud: \(title)" }
        return "iCloud: \(title), \(detail.prefix(1).lowercased())\(detail.dropFirst())"
    }
}

extension HabitLabels {
    /// The Settings status line (T-039 spec, section 5). "Last synced" shows the time today, otherwise
    /// the date.
    public static func syncStatus(_ status: SyncStatus, now: Date, timeZone: TimeZone = .autoupdatingCurrent)
        -> SyncStatusLabel
    {
        switch status {
        case .notSyncedYet: return SyncStatusLabel(title: "Not synced yet", detail: nil)
        case .syncing: return SyncStatusLabel(title: "Syncing with iCloud…", detail: nil)
        case .synced(let at):
            return SyncStatusLabel(title: "Synced with iCloud", detail: "Last synced \(when(at, now: now, timeZone))")
        case .off:
            return SyncStatusLabel(
                title: "iCloud is off",
                detail: "Habits stay on this Mac. Sign into iCloud in System Settings to sync your Macs.")
        case .waiting:
            return SyncStatusLabel(
                title: "Waiting for iCloud", detail: "Changes will sync when this Mac is back online.")
        case .full:
            return SyncStatusLabel(title: "iCloud is full", detail: "Changes stay on this Mac until there's room.")
        case .updateNeeded:
            return SyncStatusLabel(
                title: "Update HabitCal to sync",
                detail: "Another Mac has a newer version. Habits on this Mac still work.")
        case .error(let reason): return SyncStatusLabel(title: "Can't sync with iCloud", detail: reason)
        }
    }

    private static func when(_ date: Date, now: Date, _ timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = timeZone
        formatter.dateFormat = calendar.isDate(date, inSameDayAs: now) ? "h:mm a" : "MMM d"
        return formatter.string(from: date)
    }
}
