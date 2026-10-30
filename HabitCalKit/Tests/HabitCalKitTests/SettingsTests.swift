import Testing

@testable import HabitCalKit

@Suite("Settings")
struct SettingsTests {
    @Test func pickingMacDayWithoutOverrideKeepsFollowingMac() {
        #expect(WeekStart.overrideAfterPicking(.monday, current: nil, mac: .monday) == nil)
    }

    @Test func pickingWhileOverriddenKeepsOverride() {
        // Once overridden, an explicit pick sticks, even if it matches the Mac.
        #expect(WeekStart.overrideAfterPicking(.monday, current: .sunday, mac: .monday) == .monday)
    }

    @Test func pickingOtherDayOverrides() {
        #expect(WeekStart.overrideAfterPicking(.sunday, current: nil, mac: .monday) == .sunday)
    }

    @Test func launchAtLoginRegistersOnlyFirstLaunchFromApplications() {
        #expect(LaunchAtLoginPolicy.shouldRegisterAtLaunch(inApplications: true, initialized: false))
        // Already done once, or the user has touched the switch: leave it alone.
        #expect(!LaunchAtLoginPolicy.shouldRegisterAtLaunch(inApplications: true, initialized: true))
        // A copy in Downloads or a translocated path never registers (E.9).
        #expect(!LaunchAtLoginPolicy.shouldRegisterAtLaunch(inApplications: false, initialized: false))
    }

    @Test func onlyTheApplicationsFolderCountsAsInstalled() {
        #expect(LaunchAtLoginPolicy.isInApplications(bundlePath: "/Applications/HabitCal.app"))
        #expect(LaunchAtLoginPolicy.isInApplications(bundlePath: "/Applications/Utilities/HabitCal.app"))
        #expect(!LaunchAtLoginPolicy.isInApplications(bundlePath: "/Users/me/Downloads/HabitCal.app"))
        #expect(!LaunchAtLoginPolicy.isInApplications(bundlePath: "/Users/me/Applications/HabitCal.app"))
        #expect(
            !LaunchAtLoginPolicy.isInApplications(bundlePath: "/private/var/folders/x/AppTranslocation/HabitCal.app"))
        #expect(!LaunchAtLoginPolicy.isInApplications(bundlePath: "/ApplicationsOld/HabitCal.app"))
    }
}
