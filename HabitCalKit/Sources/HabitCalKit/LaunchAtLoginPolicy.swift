/// When HabitCal may register itself to launch at login (T-002 B.17, E.9, E.10).
public enum LaunchAtLoginPolicy {
    /// True only for copies under /Applications. A first launch from Downloads, or from the
    /// temporary path macOS translocates a download to, must never register: the login item would
    /// point at a copy that disappears (FM-009). `~/Applications` isn't recognized, because the
    /// sandbox hides the real home folder.
    public static func isInApplications(bundlePath: String) -> Bool {
        bundlePath.hasPrefix("/Applications/")
    }

    /// Turn launch at login on once, on the first launch from /Applications. `initialized` is set
    /// after that, and whenever the user touches the switch, so a user's "off" is never undone.
    public static func shouldRegisterAtLaunch(inApplications: Bool, initialized: Bool) -> Bool {
        inApplications && !initialized
    }
}
