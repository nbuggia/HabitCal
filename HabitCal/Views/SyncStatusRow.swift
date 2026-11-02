import HabitCalKit
import SwiftUI

/// The iCloud status line in Settings' Data section (T-039 spec, section 5): an icon, a title, and a
/// smaller second line where there is one. Read by VoiceOver as one element (E.11).
struct SyncStatusRow: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let label = HabitLabels.syncStatus(model.syncStatus, now: model.currentMoment)
        HStack(alignment: .top, spacing: 8) {
            PhosphorIcon(icon, size: 16)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(label.title)
                if let detail = label.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label.spoken)
        .accessibilityIdentifier("syncStatus")
    }

    private var icon: String {
        switch model.syncStatus {
        case .synced: return "cloud-check"
        case .off: return "cloud-slash"
        case .notSyncedYet, .syncing: return "cloud"
        case .waiting, .full, .updateNeeded, .error: return "cloud-warning"
        }
    }
}
