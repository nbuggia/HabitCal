/// Where HabitCal may launch at login from (T-002 E.9, E.10). It never turns itself on: the user
/// does, in Settings (D-011, App Store guideline 2.4.5(iii)).
public enum LaunchAtLoginPolicy {
    /// True only for copies under /Applications. A first launch from Downloads, or from the
    /// temporary path macOS translocates a download to, must never register: the login item would
    /// point at a copy that disappears (FM-009). `~/Applications` isn't recognized, because the
    /// sandbox hides the real home folder.
    public static func isInApplications(bundlePath: String) -> Bool {
        bundlePath.hasPrefix("/Applications/")
    }
}
