import AppKit
import HabitCalKit
import SwiftUI

/// Settings: About, General (launch at login, week start), Data (iCloud status, T-039), and Quit
/// (T-002 B.11–B.19).
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
                weekStartRow.frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            Text("Data")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            VStack(alignment: .leading, spacing: 0) {
                SyncStatusRow()
                Divider().padding(.vertical, 8)
                dataButton("export", "Export Habits…", spoken: "Export habits") { model.exportHabits() }
                dataButton("download-simple", "Import Habits…", spoken: "Import habits") { model.importHabits() }
                    .padding(.top, 6)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            Divider()
            quitButton
        }
        .padding(.horizontal, PopoverRoot.margin)
        .padding(.vertical, 12)
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
                .buttonStyle(.hover(outset: 3))
                .accessibilityLabel("Back")
                Spacer()
            }
        }
    }

    /// The app icon beside the name and website. It's a copy of the icon in the asset catalog, not
    /// `NSApp.applicationIconImage`: that asks macOS, which shows a blank icon until it has registered
    /// the build's icon.
    private var about: some View {
        HStack(spacing: 10) {
            Image("about-icon")
                .resizable()
                .frame(width: Self.iconSide, height: Self.iconSide)
                .accessibilityHidden(true)
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
    }

    private static let iconSide: CGFloat = 40

    /// Caption on its own line under the label and switch, like the week-start row (T-007).
    private var launchAtLoginRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Launch at login")
                Spacer()
                Toggle(
                    "Launch at login",
                    isOn: Binding(
                        get: {
                            _ = model.loginItemRevision
                            return model.loginItemState == .on
                        },
                        set: { model.setLaunchAtLogin($0) })
                )
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.small)
                .disabled(model.loginItemState == .notInApplications)
            }
            launchAtLoginCaption
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
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Open Login Items settings")
        case .notInApplications:
            caption("Move HabitCal to Applications to launch at login")
        case .on, .off:
            caption("Start HabitCal when you log in to this Mac")
        }
    }

    /// The label and a pop-up menu on one line. It shows the Mac's week start until the user picks
    /// another day (T-002 B.13); there's no caption or "Use Mac setting" (T-033).
    private var weekStartRow: some View {
        HStack {
            Text("Week starts on")
            Spacer()
            Picker(
                "Week starts on",
                selection: Binding(get: { model.weekStart }, set: { model.pickWeekStart($0) })
            ) {
                Text("Sunday").tag(WeekStart.sunday)
                Text("Monday").tag(WeekStart.monday)
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .controlSize(.small)
            .fixedSize()
        }
    }

    /// A full-width row in the Data group, like Quit. Disabled while the habits can't be read, so an
    /// import can never write over them (T-035 E.6).
    private func dataButton(_ icon: String, _ title: String, spoken: String, action: @escaping () -> Void)
        -> some View
    {
        Button(action: action) {
            HStack {
                PhosphorIcon(icon, size: 15)
                Text(title)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.hover(outset: 4))
        .disabled(!model.canAddHabits)
        .accessibilityLabel(spoken)
    }

    private var quitButton: some View {
        Button {
            NSApp.terminate(nil)
        } label: {
            HStack {
                PhosphorIcon("power", size: 15)
                Text("Quit HabitCal")
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.hover(outset: 4))
        .accessibilityLabel("Quit HabitCal")
    }

    private func caption(_ string: String) -> some View {
        Text(string).font(.caption).foregroundStyle(.secondary)
    }

    private static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
}
