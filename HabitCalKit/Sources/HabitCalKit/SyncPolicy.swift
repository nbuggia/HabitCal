import Foundation

/// The decisions HabitSync follows when CloudKit reports something (T-039 design §6). HabitSync only
/// translates CloudKit events into these calls and carries out the answers, so the rules are tested
/// here without CloudKit.
public enum SyncPolicy {
    /// What to do once a fetch from iCloud has finished.
    public struct AfterFetch: Equatable, Sendable {
        public let markFirstSyncDone: Bool
        public let sendNow: Bool
    }

    /// Nothing is sent before this Mac's first sync finishes, so a habit merged by name into an
    /// iCloud habit is never uploaded under its own ID (design §15 row 14). Nothing is sent either
    /// while another Mac has written a newer format, which this Mac could only overwrite (E.6).
    public static func answersSendBatch(firstSyncDone: Bool, updateNeeded: Bool = false) -> Bool {
        firstSyncDone && !updateNeeded
    }

    /// A CloudKit failure, as far as the status line is concerned.
    public enum Failure: Equatable, Sendable {
        case network
        case quota
        case notSignedIn
        case other(String)
    }

    /// The status line for a failure (B.5, E.3, E.5). Changes stay on the Mac and are sent later.
    public static func status(for failure: Failure) -> SyncStatus {
        switch failure {
        case .network: return .waiting
        case .quota: return .full
        case .notSignedIn: return .off
        case .other(let reason): return .error(reason)
        }
    }

    public enum AccountChange: Sendable {
        case signIn
        case switchAccounts
        case signOut
    }

    public struct AccountDecision: Equatable, Sendable {
        /// Forget everything about the old account: engine state, record versions, the first sync.
        public let resetState: Bool
        public let status: SyncStatus
    }

    /// Signing in or switching accounts starts over with a first sync into that account, which merges
    /// this Mac's habits in (E.2); signing out keeps every habit here and turns sync off (E.3).
    public static func accountChanged(_ change: AccountChange) -> AccountDecision {
        switch change {
        case .signIn, .switchAccounts: return AccountDecision(resetState: true, status: .notSyncedYet)
        case .signOut: return AccountDecision(resetState: true, status: .off)
        }
    }

    public enum Start: Equatable, Sendable {
        case resume
        /// A record was skipped as too new before this launch; fetch everything again, so a build
        /// that now knows its format gets it. Merging is idempotent, so a full refetch is safe (E.6).
        case refetchEverything
    }

    public static func atStart(updateNeeded: Bool) -> Start {
        updateNeeded ? .refetchEverything : .resume
    }

    /// Habits changed here since the last send that finished with nothing pending, to queue again at
    /// every start: a change made just before a quit or crash may not have reached the engine's saved
    /// state (E.10). With no send yet, every habit.
    public static func unsent(in habits: Habits, since lastSentAt: Date?) -> Set<UUID> {
        Set(
            habits.records.filter { habit in
                guard let lastSentAt else { return true }
                let times =
                    [habit.details.changedAt, habit.deletedAt, habit.createdAt] + habit.checks.values.map(\.changedAt)
                return times.contains { ($0 ?? .distantPast) > lastSentAt }
            }.map(\.id))
    }

    /// After iCloud's zone was deleted (the user deleted HabitCal's data, or it was reset), every record
    /// goes back, deleted habits included, so deletes still win on other Macs (E.4).
    public static func afterZoneReset(_ habits: Habits) -> Set<UUID> {
        Set(habits.records.map(\.id))
    }

    /// The first fetch that finishes completes the first sync, and the sends held during it go out at
    /// once rather than waiting for the next change (design §15 row 21).
    public static func afterFetchFinished(firstSyncDone: Bool) -> AfterFetch {
        firstSyncDone
            ? AfterFetch(markFirstSyncDone: false, sendNow: false) : AfterFetch(markFirstSyncDone: true, sendNow: true)
    }

    /// Merges habits fetched from iCloud: by the first-sync rules until the first sync is done (B.7–B.9),
    /// then the ongoing merge. The result's `toSend` lists what iCloud should get back.
    @discardableResult
    public static func apply(fetched: [Habit], to habits: inout Habits, firstSyncDone: Bool, today: Day, now: Date)
        -> MergeResult
    {
        firstSyncDone ? habits.merge(fetched) : habits.mergeFirstSync(remote: fetched, today: today, now: now)
    }

    /// A save that iCloud refused because its copy changed since: merge iCloud's copy in, and send the
    /// result again. Returns the habit to re-send.
    public static func resolveConflict(server: Habit, into habits: inout Habits) -> UUID {
        habits.merge([server])
        return server.id
    }
}
