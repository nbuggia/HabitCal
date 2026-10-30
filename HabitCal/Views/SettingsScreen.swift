import AppKit
import HabitCalKit
import SwiftUI

/// Settings: About, General (launch at login, week start), and Quit (T-002 B.11–B.19).
/// Changes apply immediately; there is no Save.
struct SettingsScreen: View {
    @Environment(AppModel.self) private var model

    private static let website = URL(string: "https://www.muchfiner.com")!

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            about
            Text("General")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            VStack(spacing: 0) {
                launchAtLoginRow
                Divider().padding(.vertical, 8)
                weekStartRow
            }
            .padding(10)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            Divider()
            quitButton
        }
        .padding(12)
    }

    private var header: some View {
        ZStack {
            Text("Settings").font(.headline)
            HStack {
                Button {
                    model.closeSettings()
                } label: {
                    HStack(spacing: 2) {
                        PhosphorIcon("caret-left", size: 13)
                        Text("Back")
                    }
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Back")
                Spacer()
            }
        }
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("HabitCal \(Self.version)").font(.body.weight(.semibold))
            Button("www.muchfiner.com") {
                NSWorkspace.shared.open(Self.website)
                model.closePopover()
            }
            .buttonStyle(.link)
            .accessibilityLabel("muchfiner.com")
        }
    }

    private var launchAtLoginRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Launch at login")
                launchAtLoginCaption
            }
            Spacer()
            Toggle(
                "Launch at login",
                isOn: Binding(
                    get: { model.loginItemState == .on },
                    set: { model.setLaunchAtLogin($0) })
            )
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.small)
            .disabled(model.loginItemState == .notInApplications)
        }
    }

    @ViewBuilder
    private var launchAtLoginCaption: some View {
        switch model.loginItemState {
        case .requiresApproval:
            Button("Needs approval in System Settings › General › Login Items") {
                model.openLoginItemsSettings()
            }
            .buttonStyle(.link)
            .font(.caption)
            .accessibilityLabel("Open Login Items settings")
        case .notInApplications:
            caption("Move HabitCal to Applications to launch at login")
        case .on, .off:
            caption("Start HabitCal when you log in to this Mac")
        }
    }

    private var weekStartRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Week starts on")
                if model.weekStartOverride == nil {
                    caption("From your Mac's settings")
                } else {
                    HStack(spacing: 4) {
                        caption("Your Mac uses \(MonthNames.weekdayName(model.macWeekStart.weekday))")
                        caption("·")
                        Button("Use Mac setting") { model.useMacWeekStart() }
                            .buttonStyle(.link)
                            .font(.caption)
                    }
                }
            }
            Spacer()
            Picker(
                "Week starts on",
                selection: Binding(get: { model.weekStart }, set: { model.pickWeekStart($0) })
            ) {
                Text("Sunday").tag(WeekStart.sunday)
                Text("Monday").tag(WeekStart.monday)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .controlSize(.small)
            .fixedSize()
        }
    }

    private var quitButton: some View {
        Button {
            NSApp.terminate(nil)
        } label: {
            HStack {
                PhosphorIcon("power", size: 15)
                Text("Quit HabitCal")
                Spacer()
                Text("⌘Q").foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("Quit HabitCal")
    }

    private func caption(_ string: String) -> some View {
        Text(string).font(.caption).foregroundStyle(.secondary)
    }

    private static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
}
