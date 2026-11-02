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

    @Test func fetchedHabitsUseTheFirstSyncMergeUntilItsDone() throws {
        var local = Habits()
        let mine = local.add(HabitDraft(name: "Run", note: "", days: [6]), today: oct(1), now: t(0))
        var remote = Habits()
        let theirs = remote.add(HabitDraft(name: "run", note: "", days: [6]), today: oct(1), now: t(1))

        var first = local
        let firstResult = SyncPolicy.apply(
            fetched: remote.records, to: &first, firstSyncDone: false, today: today, now: t(5))
        #expect(first.all.count == 1)  // paired by name
        #expect(first[theirs] != nil && first[mine] == nil)
        #expect(firstResult.toSend.contains(theirs))

        var ongoing = local
        SyncPolicy.apply(fetched: remote.records, to: &ongoing, firstSyncDone: true, today: today, now: t(5))
        #expect(ongoing.all.count == 2)  // after the first sync, same names are different habits
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
