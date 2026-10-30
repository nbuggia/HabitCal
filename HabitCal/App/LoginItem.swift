import HabitCalKit
import ServiceManagement
import os

/// What the Launch at login switch shows.
enum LoginItemState: Equatable {
    case on
    case off
    /// Registered, but macOS needs the user's approval in System Settings › Login Items (E.3, E.5).
    case requiresApproval
    /// Running from anywhere but /Applications: the switch is disabled (E.10).
    case notInApplications
}

/// Registers HabitCal to launch at login through `SMAppService`, and reports its real state.
@MainActor
struct LoginItem {
    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HabitCal", category: "LoginItem")

    let inApplications: Bool

    init(bundlePath: String = Bundle.main.bundlePath) {
        inApplications = LaunchAtLoginPolicy.isInApplications(bundlePath: bundlePath)
    }

    /// The policy wins over `SMAppService`: a Downloads copy can see `.enabled` left by an earlier
    /// registration from /Applications.
    var state: LoginItemState {
        guard inApplications else { return .notInApplications }
        switch SMAppService.mainApp.status {
        case .enabled: return .on
        case .requiresApproval: return .requiresApproval
        default: return .off
        }
    }

    /// Registers or unregisters. Failures are logged; callers re-read `state` to show the truth (E.4).
    func set(_ on: Bool) {
        guard inApplications else { return }
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            Self.log.error("Launch at login change failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
