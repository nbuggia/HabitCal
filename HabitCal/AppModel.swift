import Foundation
import HabitCalKit
import Observation
import os

/// The popover's screens. The form's contents live in `AppModel.form`, not here: changing `screen`
/// resets first responder, so a draft inside it would pull focus out of the name field on every keystroke.
enum Screen: Equatable {
    case list
    case settings
    case form
    case leaderboard
}

/// The habit form's state (T-003 §5).
struct HabitForm: Equatable {
    enum Mode: Equatable {
        case add
        case edit(UUID)
    }

    var mode: Mode
    var draft: HabitDraft
    var confirmingDelete = false
}

/// Whether habits can be shown and saved (T-003 E.5, E.6).
enum DataState: Equatable {
    case ok
    /// The file couldn't be read; nothing is saved, and Add is disabled. Holds the file's path.
    case unreadable(String)
    /// The last save failed; the change is kept on screen until a later save succeeds.
    case saveFailed
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
    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HabitCal", category: "AppModel")

    private enum Key {
        static let weekStartOverride = "weekStartOverride"
        static let launchAtLoginInitialized = "launchAtLoginInitialized"
    }

    /// Today on the Mac's calendar. Only `DayWatcher` sets it. A new day can fold away the habit
    /// whose strip has focus, so the popover takes focus back (T-012 B.5, FM-006).
    var today: Day {
        didSet { if today != oldValue { listDidHideRows() } }
    }
    /// The Mac's first day of the week, mapped to Sunday or Monday. Only `DayWatcher` sets it.
    var macWeekStart: WeekStart
    private(set) var displayedMonth: Month
    /// The day the habit list shows, or nil for today, so the selection follows today across
    /// midnight (T-022 B.8).
    private(set) var selectedDay: Day?
    private(set) var screen: Screen = .list {
        didSet { if screen != oldValue { screenDidChange() } }
    }
    /// The user's week start, or nil while following the Mac. Persisted (T-002 B.15).
    private(set) var weekStartOverride: WeekStart?
    private(set) var loginItemState: LoginItemState
    /// The user's habits. Changed only through the methods below, each of which saves (T-003 B.18).
    private(set) var habits: Habits
    private(set) var dataState: DataState
    /// Whether the habits not due today are shown under the folded row. Closed on every open (T-012 B.2).
    private(set) var showsNotDue = false
    /// The leaderboard's range; it opens on the past 7 days (T-016 B.6).
    private(set) var leaderboardRange: ConsistencyRange = .past7
    /// The open form, while `screen == .form`.
    private(set) var form: HabitForm?
    /// Bumped on every refresh, so the switch redraws even when a failed change leaves the state
    /// equal to what it was: AppKit has already flipped the switch on the click (T-002 E.4).
    private(set) var loginItemRevision = 0

    /// Closes the popover. Set by `PopoverController`.
    @ObservationIgnored var closePopover: () -> Void = {}
    /// Called after the screen changes. Set by `PopoverController` to keep Esc working (FM-006).
    @ObservationIgnored var screenDidChange: () -> Void = {}
    /// Called when rows leave the habit list, which can remove the focused strip.
    @ObservationIgnored var listDidHideRows: () -> Void = {}

    @ObservationIgnored private let store: HabitStore
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let loginItem: LoginItem

    init(store: HabitStore, today: Day, macWeekStart: WeekStart, defaults: UserDefaults, loginItem: LoginItem) {
        self.store = store
        switch store.load() {
        case .loaded(let loaded):
            habits = loaded
            dataState = .ok
        case .empty:
            habits = Habits()
            dataState = .ok
        case .unreadable(let reason):
            Self.log.error("Habits file unreadable; not saving: \(reason, privacy: .public)")
            habits = Habits()
            dataState = .unreadable(store.fileURL.path)
        }
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

    /// Bumped on every open. `PopoverRoot` rebuilds its views with it, so hover state left over
    /// when the popover closed under the pointer (Esc, ⌘-Tab) doesn't come back (T-021).
    private(set) var openGeneration = 0

    /// Every open starts from the habit list and the current month (T-002 B.4).
    func resetForOpen() {
        openGeneration += 1
        form = nil
        showsNotDue = false
        selectedDay = nil
        screen = .list
        displayedMonth = Month(today)
    }

    /// The day the habit list shows: the selected day, or today (T-022).
    var shownDay: Day {
        selectedDay ?? today
    }

    /// Selects a day from the grid; a day from a neighboring month pages to it (T-022 B.1).
    func select(_ day: Day) {
        selectedDay = day == today ? nil : day
        if !displayedMonth.contains(day) {
            displayedMonth = Month(day)
        }
    }

    func showPreviousMonth() {
        displayedMonth = displayedMonth.previous
    }

    func showNextMonth() {
        displayedMonth = displayedMonth.next
    }

    /// Back to today's month, with today selected (T-022 B.6).
    func showToday() {
        selectedDay = nil
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
        case .form:
            cancelForm()
            return .handled
        case .leaderboard:
            closeLeaderboard()
            return .handled
        }
    }

    // MARK: Habits

    func toggleNotDue() {
        showsNotDue.toggle()
        if !showsNotDue {
            listDidHideRows()
        }
    }

    /// Toggles the shown day's check-off from the done button (T-003 B.4, T-022 B.4). Future and
    /// not-due days are refused by `Habits.toggle`.
    func toggleShownDay(_ id: UUID) {
        toggle(id, on: shownDay)
    }

    /// Toggles a strip day, if it's due and not in the future (B.5, B.6).
    func toggle(_ id: UUID, on day: Day) {
        guard habits.toggle(id, on: day, today: today) else { return }
        persist()
    }

    /// Saves after every change. While the data is unreadable the store refuses, which is what
    /// keeps the user's file intact (D-004).
    private func persist() {
        guard dataState != .unreadable(store.fileURL.path) else { return }
        do {
            try store.save(habits)
            dataState = .ok
        } catch {
            Self.log.error("Saving habits failed: \(error.localizedDescription, privacy: .public)")
            dataState = .saveFailed
        }
    }

    // MARK: Habit form

    var canAddHabits: Bool {
        if case .unreadable = dataState { return false }
        return true
    }

    /// An empty form, every day selected (T-003 B.8).
    func openAddForm() {
        guard canAddHabits else { return }
        form = HabitForm(mode: .add, draft: HabitDraft(name: "", note: "", days: Set(1...7)))
        screen = .form
    }

    /// The form filled with the habit's name, current days, and note (B.9).
    func openEditForm(_ id: UUID) {
        guard let habit = habits[id] else { return }
        form = HabitForm(
            mode: .edit(id), draft: HabitDraft(name: habit.name, note: habit.note, days: habit.days(today: today)))
        screen = .form
    }

    /// Delete… from the right-click menu: the Edit form with the confirmation showing (B.15).
    func openDeleteConfirmation(_ id: UUID) {
        openEditForm(id)
        form?.confirmingDelete = true
    }

    /// Edits the draft, cut to the length limits (E.4).
    func updateDraft(_ change: (inout HabitDraft) -> Void) {
        guard var draft = form?.draft else { return }
        change(&draft)
        form?.draft = draft.clamped
    }

    func setConfirmingDelete(_ confirming: Bool) {
        form?.confirmingDelete = confirming
    }

    /// Whether the form's days differ from the habit's current ones, for the "starts today" hint.
    var formChangesSchedule: Bool {
        guard let form, case .edit(let id) = form.mode, let habit = habits[id] else { return false }
        return form.draft.days != habit.days(today: today)
    }

    /// Add or Save (B.11). Does nothing until the draft is valid (B.10). A habit saved that isn't due
    /// on the day the list shows opens the folded row, so it doesn't vanish (T-012 B.4, T-022).
    func saveForm() {
        guard let form, form.draft.isValid else { return }
        let id: UUID
        switch form.mode {
        case .add: id = habits.add(form.draft, today: today)
        case .edit(let edited):
            id = edited
            habits.update(edited, with: form.draft, today: today)
        }
        if habits[id]?.isDue(on: shownDay) == false {
            showsNotDue = true
        }
        persist()
        closeForm()
    }

    func cancelForm() {
        closeForm()
    }

    /// Deletes the habit and all its history (B.16).
    func deleteFromForm() {
        guard let form, case .edit(let id) = form.mode else { return }
        habits.delete(id)
        persist()
        closeForm()
    }

    private func closeForm() {
        form = nil
        screen = .list
    }

    // MARK: Leaderboard

    func openLeaderboard() {
        leaderboardRange = .past7
        screen = .leaderboard
    }

    /// Back to the list, on the month it was showing (T-016 B.6).
    func closeLeaderboard() {
        screen = .list
    }

    func pickLeaderboardRange(_ range: ConsistencyRange) {
        leaderboardRange = range
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
        loginItemRevision += 1
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
        loginItem.set(true)
        refreshLoginItemState()
        // Settle the default only once registration took, so a failure is retried next launch.
        if loginItemState == .on || loginItemState == .requiresApproval {
            markLaunchAtLoginInitialized()
        }
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
