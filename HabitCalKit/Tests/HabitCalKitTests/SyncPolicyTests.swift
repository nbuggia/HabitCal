import Foundation
import Testing

@testable import HabitCalKit

private func oct(_ d: Int) -> Day { Day(year: 2026, month: 10, day: d) }
private let today = oct(29)
private func t(_ seconds: Double) -> Date { Date(timeIntervalSince1970: 1_793_000_000 + seconds) }

@Suite("Sync policy")
struct SyncPolicyTests {
    @Test func syncPolicyHoldsSendsUntilFirstSyncDone() {
        #expect(!SyncPolicy.answersSendBatch(firstSyncDone: false))
        #expect(SyncPolicy.answersSendBatch(firstSyncDone: true))
    }

    @Test func syncPolicySendsWhenFirstSyncFinishes() {
        #expect(SyncPolicy.afterFetchFinished(firstSyncDone: false) == .init(markFirstSyncDone: true, sendNow: true))
        #expect(SyncPolicy.afterFetchFinished(firstSyncDone: true) == .init(markFirstSyncDone: false, sendNow: false))
    }

    @Test func fetchedHabitsMergeByIDUntilTheFirstSyncIsDone() throws {
        var local = Habits()
        let mine = local.add(HabitDraft(name: "Run", note: "", days: [6]), today: oct(1), now: t(0))
        var remote = Habits()
        remote.add(HabitDraft(name: "run", note: "", days: [6]), today: oct(1), now: t(1))

        var first = local
        SyncPolicy.apply(fetched: remote.records, to: &first, firstSyncLocalIDs: [mine], today: today, now: t(5))
        #expect(first.all.count == 2)  // a batch never pairs by name: that waits for the finish
        var ongoing = local
        SyncPolicy.apply(fetched: remote.records, to: &ongoing, firstSyncLocalIDs: nil, today: today, now: t(5))
        #expect(ongoing.all.count == 2)
    }

    @Test func firstSyncAcrossBatchesKeepsDeletesICloudHasAndPairsByNameOnce() throws {
        // This Mac: Run (deleted here, also in iCloud) and Swim (only here). iCloud: Run, and two habits
        // named Read arriving in different batches.
        var habits = Habits()
        let run = habits.add(HabitDraft(name: "Run", note: "", days: [6]), today: oct(1), now: t(0))
        let swim = habits.add(HabitDraft(name: "Swim", note: "", days: [2]), today: oct(1), now: t(0))
        var icloud = habits
        habits.delete(run, now: t(1))
        let localIDs = Set(habits.records.map(\.id))
        let read1 = icloud.add(HabitDraft(name: "Read", note: "", days: [6]), today: oct(1), now: t(2))
        let read2 = icloud.add(HabitDraft(name: "Read", note: "", days: [6]), today: oct(1), now: t(3))
        let batch1 = icloud.records.filter { [run, read1].contains($0.id) }
        let batch2 = icloud.records.filter { $0.id == read2 }

        let r1 = habits.mergeFirstSyncBatch(batch1, localIDs: localIDs, today: today, now: t(5))
        let r2 = habits.mergeFirstSyncBatch(batch2, localIDs: localIDs, today: today, now: t(5))
        let finish = habits.finishFirstSync(
            localIDs: localIDs, remoteIDs: [run, read1, read2], today: today, now: t(5))
        let toSend = r1.toSend.union(r2.toSend).union(finish.toSend)

        #expect(habits.records.contains { $0.id == run && $0.isDeleted })  // the delete is kept
        #expect(toSend.contains(run))  // and goes to iCloud
        #expect(Set(habits.all.map(\.id)) == [swim, read1, read2])  // iCloud's two Reads aren't paired with each other
        #expect(toSend.contains(swim))
        #expect(!toSend.contains(read1) && !toSend.contains(read2))
    }

    @Test func firstSyncWithOneCopyWithoutTimesUsesTheMostRecentCheckOff() throws {
        let id = UUID()
        var newer = Habits()
        let stamped = newer.add(HabitDraft(name: "Run there", note: "", days: [6]), today: oct(1), now: t(0))
        newer.toggle(stamped, on: oct(16), today: today, now: t(0))
        let remoteCopy = try #require(newer.records.first)
        let remote = Habit(
            id: id, details: remoteCopy.details, addedOn: oct(1), createdAt: remoteCopy.createdAt, deletedAt: nil,
            checks: remoteCopy.checks)
        let local = Habit(
            id: id, name: "Run here", note: "", addedOn: oct(1), schedule: [ScheduleEntry(from: oct(1), days: [6])],
            checkOffs: [oct(23)])  // saved before sync existed: no change times
        var habits = Habits([local])
        habits.mergeFirstSync(remote: [remote], today: today, now: t(5))
        #expect(habits[id]?.name == "Run here")  // checked off more recently (B.8b)
    }

    @Test func conflictMergesTheServerCopyAndResends() throws {
        var habits = Habits()
        let id = habits.add(HabitDraft(name: "Run", note: "", days: [6, 1]), today: oct(1), now: t(0))
        var server = habits
        server.toggle(id, on: oct(25), today: today, now: t(2))
        habits.toggle(id, on: oct(23), today: today, now: t(3))
        let resend = SyncPolicy.resolveConflict(server: try #require(server.records.first), into: &habits)
        #expect(resend == id)
        let merged = try #require(habits[id])
        #expect(merged.isDone(on: oct(23)) && merged.isDone(on: oct(25)))
    }
}

@Suite("Sync recovery")
struct SyncRecoveryTests {
    @Test func syncPolicyStopsSendingWhileAnUpdateIsNeeded() {
        #expect(!SyncPolicy.answersSendBatch(firstSyncDone: true, updateNeeded: true))
        #expect(SyncPolicy.answersSendBatch(firstSyncDone: true, updateNeeded: false))
    }

    @Test func errorsMapToTheStatusLine() {
        #expect(SyncPolicy.status(for: .network) == .waiting)
        #expect(SyncPolicy.status(for: .quota) == .full)
        #expect(SyncPolicy.status(for: .notSignedIn) == .off)
        #expect(SyncPolicy.status(for: .other("Bad request")) == .error("Bad request"))
    }

    @Test func signInOrSwitchStartsAFirstSyncAndSignOutTurnsSyncOff() {
        #expect(SyncPolicy.accountChanged(.signIn) == .init(resetState: true, status: .notSyncedYet))
        #expect(SyncPolicy.accountChanged(.switchAccounts) == .init(resetState: true, status: .notSyncedYet))
        #expect(SyncPolicy.accountChanged(.signOut) == .init(resetState: true, status: .off))
    }

    @Test func aStartAfterAnUpdateNeededFetchesEverythingAgain() {
        #expect(SyncPolicy.atStart(updateNeeded: true) == .refetchEverything)
        #expect(SyncPolicy.atStart(updateNeeded: false) == .resume)
    }

    @Test func syncPolicyRequeuesUnsentChangesAtStart() {
        var habits = Habits()
        let old = habits.add(HabitDraft(name: "Run", note: "", days: [6]), today: oct(1), now: t(0))
        let newer = habits.add(HabitDraft(name: "Read", note: "", days: [6]), today: oct(1), now: t(0))
        let gone = habits.add(HabitDraft(name: "Swim", note: "", days: [6]), today: oct(1), now: t(0))
        habits.toggle(newer, on: oct(23), today: today, now: t(20))
        habits.delete(gone, now: t(30))
        let requeue = SyncPolicy.unsent(in: habits, since: t(10))
        #expect(requeue == [newer, gone])
        #expect(!requeue.contains(old))
        #expect(SyncPolicy.unsent(in: habits, since: nil) == [old, newer, gone])
    }

    @Test func aDeletedZoneResendsEveryRecord() {
        var habits = Habits()
        let a = habits.add(HabitDraft(name: "Run", note: "", days: [6]), today: oct(1), now: t(0))
        let b = habits.add(HabitDraft(name: "Swim", note: "", days: [6]), today: oct(1), now: t(0))
        habits.delete(b, now: t(1))
        #expect(SyncPolicy.afterZoneReset(habits) == [a, b])  // deleted ones too, so deletes still win
    }
}
