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
    /// iCloud habit is never uploaded under its own ID (design §15 row 14).
    public static func answersSendBatch(firstSyncDone: Bool) -> Bool {
        firstSyncDone
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
