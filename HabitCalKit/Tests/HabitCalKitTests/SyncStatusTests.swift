import Foundation
import Testing

@testable import HabitCalKit

@Suite("Sync status")
struct SyncStatusTests {
    private let utc = TimeZone(identifier: "UTC")!
    /// 2026-10-26 09:41 UTC.
    private let now = Date(timeIntervalSince1970: 1_793_007_660)

    private func label(_ status: SyncStatus) -> SyncStatusLabel {
        HabitLabels.syncStatus(status, now: now, timeZone: utc)
    }

    @Test func syncStatusLabels() {
        #expect(label(.synced(now)).title == "Synced with iCloud")
        #expect(label(.synced(now)).detail == "Last synced 9:41 AM")
        #expect(label(.synced(now.addingTimeInterval(-86_400 * 3))).detail == "Last synced Oct 23")
        #expect(label(.syncing).title == "Syncing with iCloud…")
        #expect(label(.syncing).detail == nil)
        #expect(label(.notSyncedYet).title == "Not synced yet")
        #expect(label(.off).title == "iCloud is off")
        #expect(
            label(.off).detail == "Habits stay on this Mac. Sign into iCloud in System Settings to sync your Macs.")
        #expect(label(.waiting).title == "Waiting for iCloud")
        #expect(label(.waiting).detail == "Changes will sync when this Mac is back online.")
        #expect(label(.full).title == "iCloud is full")
        #expect(label(.full).detail == "Changes stay on this Mac until there's room.")
        #expect(label(.updateNeeded).title == "Update HabitCal to sync")
        #expect(label(.updateNeeded).detail == "Another Mac has a newer version. Habits on this Mac still work.")
        #expect(label(.error("The request timed out.")).title == "Can't sync with iCloud")
        #expect(label(.error("The request timed out.")).detail == "The request timed out.")
    }

    @Test func spokenStatusIsOneSentence() {
        #expect(label(.synced(now)).spoken == "iCloud: Synced with iCloud, last synced 9:41 AM")
        #expect(label(.syncing).spoken == "iCloud: Syncing with iCloud…")
    }

    @Test func syncNowOnlyWhenICloudIsAvailableAndIdle() {
        #expect(SyncStatus.synced(now).allowsSyncNow)
        #expect(SyncStatus.notSyncedYet.allowsSyncNow)
        #expect(SyncStatus.waiting.allowsSyncNow)
        #expect(SyncStatus.error("x").allowsSyncNow)
        #expect(!SyncStatus.syncing.allowsSyncNow)
        #expect(!SyncStatus.off.allowsSyncNow)
        #expect(!SyncStatus.updateNeeded.allowsSyncNow)
    }

    @Test func debugNamesParseForTheTestLaunchArgument() {
        #expect(SyncStatus(debugName: "off") == .off)
        #expect(SyncStatus(debugName: "full") == .full)
        #expect(SyncStatus(debugName: "nonsense") == nil)
    }
}
