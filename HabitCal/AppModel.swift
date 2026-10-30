import Foundation
import HabitCalKit
import Observation

/// The popover's screens. T-003 adds the habit form.
enum Screen: Equatable {
    case list
    case settings
}

/// What Esc did: handled inside the popover, or nothing left to back out of, so close it.
enum EscapeResult {
    case handled
    case closePopover
}

/// The app's state, shared by the menu bar and every popover screen.
@MainActor
@Observable
final class AppModel {
    private enum Key {
        static let weekStartOverride = "weekStartOverride"
        static let launchAtLoginInitialized = "launchAtLoginInitialized"
    }

    /// Today on the Mac's calendar. Only `DayWatcher` sets it.
    var today: Day
    /// The Mac's first day of the week, mapped to Sunday or Monday. Only `DayWatcher` sets it.
    var macWeekStart: WeekStart
    private(set) var displayedMonth: Month
    private(set) var screen: Screen = .list
    /// The user's week start, or nil while following the Mac. Persisted (T-002 B.15).
    private(set) var weekStartOverride: WeekStart?
    private(set) var loginItemState: LoginItemState

    /// Closes the popover. Set by `PopoverController`.
    @ObservationIgnored var closePopover: () -> Void = {}

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let loginItem: LoginItem

    init(today: Day, macWeekStart: WeekStart, defaults: UserDefaults, loginItem: LoginItem) {
        self.today = today
        self.macWeekStart = macWeekStart
        self.defaults = defaults
        self.loginItem = loginItem
        displayedMonth = Month(today)
        // An unknown stored value reads as no override.
        weekStartOverride = defaults.string(forKey: Key.weekStartOverride).flatMap(WeekStart.init(rawValue:))
        loginItemState = loginItem.state
    }

    var weekStart: WeekStart {
        WeekStart.resolve(override: weekStartOverride, mac: macWeekStart)
    }

    var gridDays: [Day] {
        MonthGrid.days(in: displayedMonth, weekStart: weekStart)
    }

    // MARK: Popover and calendar

    /// Every open starts from the habit list and the current month (T-002 B.4).
    func resetForOpen() {
        screen = .list
        displayedMonth = Month(today)
    }

    func showPreviousMonth() {
        displayedMonth = displayedMonth.previous
    }

    func showNextMonth() {
        displayedMonth = displayedMonth.next
    }

    func showToday() {
        displayedMonth = Month(today)
    }

    /// Esc backs out one level at a time, and closes the popover from the list (T-002 B.5).
    func escape() -> EscapeResult {
        switch screen {
        case .list:
            return .closePopover
        case .settings:
            closeSettings()
            return .handled
        }
    }

    // MARK: Settings

    func openSettings() {
        refreshLoginItemState()
        screen = .settings
    }

    /// Back to the list, on the month it was showing (T-002 B.11).
    func closeSettings() {
        screen = .list
    }

    func pickWeekStart(_ picked: WeekStart) {
        setWeekStartOverride(WeekStart.overrideAfterPicking(picked, current: weekStartOverride, mac: macWeekStart))
    }

    func useMacWeekStart() {
        setWeekStartOverride(nil)
    }

    /// Re-reads launch at login from macOS. The user can change it in System Settings at any time (E.5).
    func refreshLoginItemState() {
        loginItemState = loginItem.state
    }

    func setLaunchAtLogin(_ on: Bool) {
        // Touching the switch settles the first-launch default, so a user's "off" is never undone (B.17).
        markLaunchAtLoginInitialized()
        loginItem.set(on)
        refreshLoginItemState()
    }

    func openLoginItemsSettings() {
        loginItem.openSystemSettings()
    }

    /// Turns launch at login on, once, on the first launch from /Applications (B.17, E.9).
    func applyFirstLaunchLoginItemDefault() {
        let initialized = defaults.bool(forKey: Key.launchAtLoginInitialized)
        guard
            LaunchAtLoginPolicy.shouldRegisterAtLaunch(
                inApplications: loginItem.inApplications, initialized: initialized)
        else { return }
        markLaunchAtLoginInitialized()
        loginItem.set(true)
        refreshLoginItemState()
    }

    private func markLaunchAtLoginInitialized() {
        defaults.set(true, forKey: Key.launchAtLoginInitialized)
    }

    private func setWeekStartOverride(_ override: WeekStart?) {
        weekStartOverride = override
        if let override {
            defaults.set(override.rawValue, forKey: Key.weekStartOverride)
        } else {
            defaults.removeObject(forKey: Key.weekStartOverride)
        }
    }
}
