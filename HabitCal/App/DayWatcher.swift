import AppKit
import HabitCalKit

/// Keeps `AppModel.today` and `AppModel.macWeekStart` current. A day-change notification alone misses
/// midnight while the Mac sleeps, so it also listens for wake, clock, and time zone changes, with a
/// once-a-minute fallback (FM-001, T-002 B.2). Locale changes catch a new First day of week (FM-005).
@MainActor
final class DayWatcher {
    private static let fallbackInterval: TimeInterval = 60

    private let source: any TodaySource
    private let macFirstWeekday: () -> Int
    private let model: AppModel
    private let onTodayChange: (Day) -> Void
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []
    private var timer: Timer?

    init(
        source: any TodaySource, macFirstWeekday: @escaping () -> Int, model: AppModel,
        onTodayChange: @escaping (Day) -> Void
    ) {
        self.source = source
        self.macFirstWeekday = macFirstWeekday
        self.model = model
        self.onTodayChange = onTodayChange

        let local = NotificationCenter.default
        let workspace = NSWorkspace.shared.notificationCenter
        observe(.NSCalendarDayChanged, on: local)
        observe(.NSSystemClockDidChange, on: local)
        observe(.NSSystemTimeZoneDidChange, on: local)
        observe(NSLocale.currentLocaleDidChangeNotification, on: local)
        observe(NSWorkspace.didWakeNotification, on: workspace)
        timer = Timer.scheduledTimer(withTimeInterval: Self.fallbackInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.recompute() }
        }
    }

    /// Reads today and the Mac's week start again, and reports today only when the date actually changed.
    func recompute() {
        let macWeekStart = WeekStart.fromMac(firstWeekday: macFirstWeekday())
        if macWeekStart != model.macWeekStart {
            model.macWeekStart = macWeekStart
        }

        let today = source.today(in: .autoupdatingCurrent)
        guard today != model.today else { return }
        model.today = today
        onTodayChange(today)
    }

    private func observe(_ name: Notification.Name, on center: NotificationCenter) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.recompute() }
        }
        observers.append((center, token))
    }
}
