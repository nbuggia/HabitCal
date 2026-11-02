import HabitCalKit
import SwiftUI

/// The iCloud status line in Settings' Data section (T-039 spec, section 5): an icon, a title, a
/// smaller second line where there is one, and Sync Now (B.22). The line is read by VoiceOver as one
/// element (E.11).
struct SyncStatusRow: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let label = HabitLabels.syncStatus(model.syncStatus, now: model.currentMoment)
        VStack(alignment: .leading, spacing: 4) {
            line(label)
            if showsSyncNow {
                syncNowButton
                    .padding(.leading, 24)
            }
        }
    }

    private func line(_ label: SyncStatusLabel) -> some View {
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

    /// Hover and pressed states like every popover button (T-021); while syncing, a spinner and
    /// "Syncing…" in place of its title, for at least a second (B.22).
    private var syncNowButton: some View {
        let syncing = model.syncStatus == .syncing
        return Button {
            model.syncNow()
        } label: {
            HStack(spacing: 4) {
                if syncing {
                    ProgressView().controlSize(.mini)
                }
                Text(syncing ? "Syncing…" : "Sync Now")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(syncing ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.accentColor))
            .contentShape(Rectangle())
        }
        .buttonStyle(.hover(outset: 3))
        .disabled(!model.syncStatus.allowsSyncNow)
        .accessibilityLabel("Sync Now")
    }

    /// Shown whenever iCloud can be used; disabled while syncing.
    private var showsSyncNow: Bool {
        switch model.syncStatus {
        case .off, .updateNeeded: return false
        default: return true
        }
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
