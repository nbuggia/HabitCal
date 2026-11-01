import Foundation
import Testing

@testable import HabitCalKit

/// Oct 2026: the 29th ("today") is a Thursday; the 25th a Sunday; the 23rd a Friday.
private func oct(_ d: Int) -> Day { Day(year: 2026, month: 10, day: d) }
private let today = oct(29)
private let fri = 6
private let sun = 1
private let mon = 2
private let thu = 5

/// A moment on the test day: `t(1)` is one second after the base, so later arguments are later changes.
private func t(_ seconds: Double) -> Date { Date(timeIntervalSince1970: 1_793_000_000 + seconds) }

/// Two Macs that synced: both hold the same habits.
private func twoMacs(_ build: (inout Habits) -> Void) -> (Habits, Habits) {
    var habits = Habits()
    build(&habits)
    return (habits, habits)
}

private func draft(_ name: String, note: String = "", days: Set<Int>) -> HabitDraft {
    HabitDraft(name: name, note: note, days: days)
}

/// Merges each side's records into the other, as two syncing Macs end up doing.
private func sync(_ a: inout Habits, _ b: inout Habits) {
    let fromA = a.records
    let fromB = b.records
    a.merge(fromB)
    b.merge(fromA)
}

@Suite("Merging")
struct MergeTests {
    // MARK: Conflict table

    @Test func checkAndUncheckSameDayLaterWins() throws {
        var id = UUID()
        var (a, b) = twoMacs { id = $0.add(draft("Run", days: [fri, sun]), today: oct(1), now: t(0)) }
        b.toggle(id, on: oct(25), today: today, now: t(1))  // B checks Sunday
        b.toggle(id, on: oct(25), today: today, now: t(3))  // ...and unchecks it later
        a.toggle(id, on: oct(25), today: today, now: t(2))  // A checks it in between
        sync(&a, &b)
        #expect(try !#require(a[id]).isDone(on: oct(25)))
        #expect(a == b)
    }

    @Test func checksOnBothMacsAreBothDone() throws {
        var id = UUID()
        var (a, b) = twoMacs { id = $0.add(draft("Run", days: [fri, sun]), today: oct(1), now: t(0)) }
        a.toggle(id, on: oct(25), today: today, now: t(1))
        b.toggle(id, on: oct(25), today: today, now: t(2))
        sync(&a, &b)
        #expect(try #require(a[id]).isDone(on: oct(25)))
        #expect(a == b)
    }

    @Test func editsToDifferentDaysAndHabitsBothKept() throws {
        var run = UUID()
        var read = UUID()
        var (a, b) = twoMacs {
            run = $0.add(draft("Run", days: [fri, sun]), today: oct(1), now: t(0))
            read = $0.add(draft("Read", days: Set(1...7)), today: oct(1), now: t(0))
        }
        a.toggle(run, on: oct(23), today: today, now: t(1))
        b.toggle(run, on: oct(25), today: today, now: t(2))
        b.toggle(read, on: oct(28), today: today, now: t(3))
        sync(&a, &b)
        let merged = try #require(a[run])
        #expect(merged.isDone(on: oct(23)) && merged.isDone(on: oct(25)))
        #expect(try #require(a[read]).isDone(on: oct(28)))
        #expect(a == b)
    }

    @Test func laterDetailsEditWinsAsAWhole() throws {
        var id = UUID()
        var (a, b) = twoMacs { id = $0.add(draft("Run", days: [fri, sun]), today: oct(1), now: t(0)) }
        a.setDetails(id, draft("Long run", days: [fri, sun]), today: today, now: t(1))  // rename on A
        b.setDetails(id, draft("Run", note: "5k", days: [fri, sun]), today: today, now: t(2))  // note on B, later
        sync(&a, &b)
        let habit = try #require(a[id])
        #expect(habit.name == "Run")  // the later edit wins whole: A's rename is lost (spec, customer 2026-11-01)
        #expect(habit.note == "5k")
        #expect(a == b)
    }

    @Test func deleteBeatsALaterCheckOffOrEdit() {
        var id = UUID()
        var (a, b) = twoMacs { id = $0.add(draft("Run", days: [fri, sun]), today: oct(1), now: t(0)) }
        a.delete(id, now: t(1))
        b.toggle(id, on: oct(25), today: today, now: t(2))
        b.setDetails(id, draft("Long run", days: [fri]), today: today, now: t(3))
        sync(&a, &b)
        #expect(a[id] == nil)
        #expect(b[id] == nil)
        #expect(a.all.isEmpty && a == b)
    }

    @Test func addsOnBothMacsBothKept() {
        var (a, b) = twoMacs { _ in }
        a.add(draft("Run", days: [fri]), today: today, now: t(1))
        b.add(draft("Run", days: [fri]), today: today, now: t(2))  // same name: both kept after first sync
        sync(&a, &b)
        #expect(a.all.count == 2)
        #expect(a == b)
    }

    @Test func checkOffOnADayAnotherMacUnscheduledStaysDueAndDone() throws {
        var id = UUID()
        var (a, b) = twoMacs { id = $0.add(draft("Run", days: [fri, sun]), today: oct(1), now: t(0)) }
        // On the 23rd, Mac B checks off Friday while Mac A, offline, changes the schedule to Sundays only
        // from that day. A's edit is later, so its schedule wins, but B's check-off isn't dropped.
        b.toggle(id, on: oct(23), today: today, now: t(1))  // Friday, done on B
        a.setDetails(id, draft("Run", days: [sun]), today: oct(23), now: t(2))  // A: Sundays only, from the 23rd
        sync(&a, &b)
        let habit = try #require(a[id])
        #expect(habit.isDone(on: oct(23)))
        #expect(habit.isDue(on: oct(23)))  // a check-off makes its day due (B.21)
        #expect(Streaks.best(habit, today: today) >= 1)  // the 23rd counts; the 25th, a missed Sunday, ends it
        #expect(a == b)
    }

    // MARK: Order independence

    @Test func mergeIsOrderIndependent() {
        var id = UUID()
        var base = Habits()
        id = base.add(draft("Run", days: [fri, sun]), today: oct(1), now: t(0))
        var copies = [base, base, base]
        copies[0].toggle(id, on: oct(25), today: today, now: t(1))
        copies[1].toggle(id, on: oct(25), today: today, now: t(1))  // same moment: the tie rule decides
        copies[1].toggle(id, on: oct(25), today: today, now: t(1))
        copies[2].setDetails(id, draft("Long run", days: [fri]), today: today, now: t(2))
        copies[0].add(draft("Read", days: Set(1...7)), today: today, now: t(3))
        let orders = [[0, 1, 2], [2, 1, 0], [1, 0, 2], [2, 0, 1]]
        let results = orders.map { order -> Habits in
            var result = Habits()
            for index in order { result.merge(copies[index].records) }
            result.merge(result.records)  // idempotent
            return result
        }
        #expect(Set(results.map(\.records)).count == 1)
    }

    @Test func tiesBreakTheSameWayEverywhere() throws {
        var id = UUID()
        var (a, b) = twoMacs { id = $0.add(draft("Run", days: [fri, sun]), today: oct(1), now: t(0)) }
        a.setDetails(id, draft("Alpha", days: [fri]), today: today, now: t(5))
        b.setDetails(id, draft("Beta", days: [fri]), today: today, now: t(5))
        sync(&a, &b)
        #expect(a == b)
        #expect(try #require(a[id]).name == "Beta")  // the larger value wins a tie
    }

    // MARK: Import

    @Test func importDeletesKnownHabitsAndAddsNewOnes() {
        var habits = Habits()
        let run = habits.add(draft("Run", days: [fri]), today: oct(1), now: t(0))
        var file = Habits()
        let fileRun = file.add(draft("Run", days: [fri, sun]), today: oct(1), now: t(0))
        file.toggle(fileRun, on: oct(23), today: today, now: t(0))
        habits.replaceAll(with: file.all, now: t(10))
        #expect(habits[run] == nil)
        #expect(habits.all.map(\.name) == ["Run"])
        #expect(habits.all[0].id != run && habits.all[0].id != fileRun)  // new ID
        #expect(habits.all[0].isDone(on: oct(23)))
    }

    @Test func importKeepsTheFilesOrder() {
        var file = Habits()
        file.add(draft("B", days: [fri]), today: oct(1), now: t(0))
        file.add(draft("A", days: [fri]), today: oct(1), now: t(0))
        var habits = Habits()
        habits.replaceAll(with: file.all, now: t(10))
        #expect(habits.all.map(\.name) == ["B", "A"])
    }

    @Test func editsToAHabitTheImportDeletedAreLost() {
        var run = UUID()
        var (a, b) = twoMacs { run = $0.add(draft("Run", days: [fri, sun]), today: oct(1), now: t(0)) }
        b.toggle(run, on: oct(25), today: today, now: t(1))  // B, offline
        var file = Habits()
        file.add(draft("Swim", days: [mon]), today: oct(1), now: t(0))
        a.replaceAll(with: file.all, now: t(2))
        sync(&a, &b)
        #expect(a.all.map(\.name) == ["Swim"])
        #expect(a == b)
    }

    @Test func aHabitTheImporterDidntKnowSurvivesImport() {
        var (a, b) = twoMacs { $0.add(draft("Run", days: [fri]), today: oct(1), now: t(0)) }
        b.add(draft("Read", days: Set(1...7)), today: today, now: t(1))  // B, offline
        var file = Habits()
        file.add(draft("Swim", days: [mon]), today: oct(1), now: t(0))
        a.replaceAll(with: file.all, now: t(2))
        sync(&a, &b)
        #expect(Set(a.all.map(\.name)) == ["Swim", "Read"])
        #expect(a == b)
    }

    @Test func changesAfterImportApplyToImportedHabits() throws {
        var (a, b) = twoMacs { $0.add(draft("Run", days: [fri]), today: oct(1), now: t(0)) }
        var file = Habits()
        file.add(draft("Swim", days: [thu]), today: oct(1), now: t(0))
        a.replaceAll(with: file.all, now: t(2))
        sync(&a, &b)
        let swim = try #require(b.all.first)
        b.toggle(swim.id, on: today, today: today, now: t(3))
        sync(&a, &b)
        #expect(try #require(a[swim.id]).isDone(on: today))
    }

    // MARK: First sync

    @Test func firstSyncKeepsEveryHabitAndCheckOff() {
        var local = Habits()
        let run = local.add(draft("Run", days: [fri, sun]), today: oct(1), now: t(0))
        local.toggle(run, on: oct(25), today: today, now: t(1))
        var remote = Habits()
        let read = remote.add(draft("Read", days: Set(1...7)), today: oct(1), now: t(0))
        remote.toggle(read, on: oct(28), today: today, now: t(2))
        let result = local.mergeFirstSync(remote: remote.records, today: today, now: t(5))
        #expect(Set(local.all.map(\.name)) == ["Run", "Read"])
        #expect(local[run]?.isDone(on: oct(25)) == true)
        #expect(local[read]?.isDone(on: oct(28)) == true)
        #expect(result.toSend.contains(run))
        #expect(!result.toSend.contains(read))
    }

    @Test func firstSyncMergesSameIdAndSameName() throws {
        var local = Habits()
        let localRun = local.add(draft("Run", days: [fri, sun]), today: oct(1), now: t(0))
        local.toggle(localRun, on: oct(23), today: today, now: t(1))
        var remote = Habits()
        let remoteRun = remote.add(draft("  run ", days: [fri, sun]), today: oct(1), now: t(0))
        remote.toggle(remoteRun, on: oct(25), today: today, now: t(2))
        let result = local.mergeFirstSync(remote: remote.records, today: today, now: t(5))
        #expect(local.all.count == 1)
        let merged = try #require(local[remoteRun])  // keeps the remote ID
        #expect(local[localRun] == nil)
        #expect(merged.isDone(on: oct(23)) && merged.isDone(on: oct(25)))
        #expect(result.toSend.contains(remoteRun))
        #expect(!result.toSend.contains(localRun))  // the local ID is never sent
    }

    @Test func firstSyncNeverPairsWithADeletedHabit() {
        var local = Habits()
        let run = local.add(draft("Run", days: [fri]), today: oct(1), now: t(0))
        local.toggle(run, on: oct(23), today: today, now: t(1))
        var remote = Habits()
        let gone = remote.add(draft("Run", days: [fri]), today: oct(1), now: t(0))
        remote.delete(gone, now: t(2))
        local.mergeFirstSync(remote: remote.records, today: today, now: t(5))
        #expect(local[run]?.isDone(on: oct(23)) == true)
        #expect(local.all.count == 1)
    }

    @Test func firstSyncPastDaysDueOnlyIfDueInBoth() throws {
        var local = Habits()
        let a = local.add(draft("Run", days: [fri, sun]), today: oct(1), now: t(0))
        var remote = Habits()
        let b = remote.add(draft("Run", days: [fri, mon]), today: oct(1), now: t(1))
        remote.toggle(b, on: oct(26), today: today, now: t(2))  // a Monday, done on the remote copy
        local.mergeFirstSync(remote: remote.records, today: today, now: t(5))
        let merged = try #require(local[b])
        #expect(local[a] == nil)
        #expect(merged.isDue(on: oct(23)))  // Friday: due in both
        #expect(!merged.isDue(on: oct(25)))  // Sunday: only local had it, and it wasn't done: not a missed day
        #expect(merged.isDue(on: oct(26)) && merged.isDone(on: oct(26)))  // Monday: done, so due (B.21)
        #expect(!merged.isDue(on: oct(19)))  // an unchecked Monday: only remote had it
    }

    @Test func firstSyncMergedHabitHasDaysToday() throws {
        var local = Habits()
        local.add(draft("Run", days: [fri]), today: oct(1), now: t(0))
        var remote = Habits()
        let b = remote.add(draft("Run", days: [sun]), today: oct(1), now: t(1))  // changed later: wins
        local.mergeFirstSync(remote: remote.records, today: today, now: t(5))
        let merged = try #require(local[b])
        #expect(merged.days(today: today) == [sun])
        #expect(merged.isDue(on: Day(year: 2026, month: 11, day: 1)))  // next Sunday
        #expect(HabitDraft(name: merged.name, note: merged.note, days: merged.days(today: today)).isValid)
    }

    @Test func firstSyncWithoutTimesUsesMostRecentCheckOff() throws {
        // Saved before sync existed: no change times (B.8b).
        let id = UUID()
        let local = Habit(
            id: id, name: "Run here", note: "", addedOn: oct(1), schedule: [ScheduleEntry(from: oct(1), days: [fri])],
            checkOffs: [oct(23)])
        let remoteCopy = Habit(
            id: id, name: "Run there", note: "", addedOn: oct(1),
            schedule: [ScheduleEntry(from: oct(1), days: [fri])], checkOffs: [oct(16)])
        var habits = Habits([local])
        habits.mergeFirstSync(remote: [remoteCopy], today: today, now: t(5))
        let merged = try #require(habits[id])
        #expect(merged.name == "Run here")  // the copy checked off most recently
        #expect(merged.checkOffs == [oct(16), oct(23)])
    }

    @Test func mergedHabitKeepsEarlierAddedDate() throws {
        var local = Habits()
        local.add(draft("Run", days: [fri]), today: Day(year: 2026, month: 9, day: 1), now: t(0))
        var remote = Habits()
        let b = remote.add(draft("Run", days: [fri]), today: oct(1), now: t(1))
        local.mergeFirstSync(remote: remote.records, today: today, now: t(5))
        #expect(try #require(local[b]).addedOn == Day(year: 2026, month: 9, day: 1))
    }

    @Test func firstSyncPairKeepsTimestampedCheckOffsOlderThanTheOtherCopy() throws {
        var local = Habits()
        let a = local.add(draft("Push-ups", days: Set(1...7)), today: oct(1), now: t(0))
        local.toggle(a, on: oct(2), today: today, now: t(1))  // long before the remote copy existed
        var remote = Habits()
        let b = remote.add(draft("Push-ups", days: Set(1...7)), today: oct(20), now: t(100))
        local.mergeFirstSync(remote: remote.records, today: today, now: t(200))
        #expect(try #require(local[b]).isDone(on: oct(2)))
    }

    @Test func firstSyncResultUnchangedByLaterOngoingMerge() {
        // Mac B joins; Mac C (already synced with iCloud) receives B's first-sync result.
        var remote = Habits()
        let b = remote.add(draft("Push-ups", days: [fri, sun]), today: oct(20), now: t(100))
        remote.toggle(b, on: oct(25), today: today, now: t(101))
        var macC = remote
        var macB = Habits()
        let local = macB.add(draft("Push-ups", days: [fri, mon]), today: oct(1), now: t(0))
        macB.toggle(local, on: oct(2), today: today, now: t(1))
        macB.mergeFirstSync(remote: remote.records, today: today, now: t(200))
        macC.merge(macB.records)
        macB.merge(macC.records)
        #expect(macB == macC)
        #expect(macC[b]?.isDone(on: oct(2)) == true)
        #expect(macC[b]?.isDone(on: oct(25)) == true)
    }

    @Test func mergedOrderIsTheSameOnEveryMac() {
        var a = Habits()
        a.add(draft("Run", days: [fri]), today: oct(1), now: t(1))
        var b = Habits()
        b.add(draft("Read", days: [fri]), today: oct(1), now: t(2))
        b.add(draft("Swim", days: [fri]), today: oct(1), now: t(0.5))
        sync(&a, &b)
        #expect(a.all.map(\.name) == b.all.map(\.name))
        // By the moment each was added; Swim went last on its Mac even with an earlier clock reading.
        #expect(a.all.map(\.name) == ["Run", "Read", "Swim"])
    }

    // MARK: Form edits

    @Test func formEditKeepsRemoteCheckOffsAndOtherHabits() throws {
        var id = UUID()
        var read = UUID()
        var (a, b) = twoMacs {
            id = $0.add(draft("Run", days: [fri, sun]), today: oct(1), now: t(0))
            read = $0.add(draft("Read", days: Set(1...7)), today: oct(1), now: t(0))
        }
        b.toggle(id, on: oct(25), today: today, now: t(1))
        b.toggle(read, on: oct(28), today: today, now: t(1))
        a.merge(b.records)  // arrives while A's form is open
        a.applyFormEdit(
            id, draft: draft("Long run", days: [fri, sun]), todayDoneAtOpen: false, today: today, now: t(2))
        #expect(try #require(a[id]).isDone(on: oct(25)))
        #expect(try #require(a[read]).isDone(on: oct(28)))
        #expect(a[id]?.name == "Long run")
    }

    @Test func formEditRestoresTodayWhenItsDayComesBack() throws {
        var habits = Habits()
        let id = habits.add(draft("Push-ups", days: Set(1...7)), today: oct(1), now: t(0))
        habits.toggle(id, on: today, today: today, now: t(1))
        let all = Set(1...7)
        habits.applyFormEdit(
            id, draft: draft("Push-ups", days: all.subtracting([thu])), todayDoneAtOpen: true, today: today, now: t(2))
        #expect(try !#require(habits[id]).isDone(on: today))
        habits.applyFormEdit(id, draft: draft("Push-ups", days: all), todayDoneAtOpen: true, today: today, now: t(3))
        #expect(try #require(habits[id]).isDone(on: today))
    }

    @Test func formEditIgnoresAnInvalidDraft() throws {
        var habits = Habits()
        let id = habits.add(draft("Run", days: [fri]), today: oct(1), now: t(0))
        habits.applyFormEdit(id, draft: draft("", days: [fri]), todayDoneAtOpen: false, today: today, now: t(1))
        habits.applyFormEdit(id, draft: draft("Run", days: []), todayDoneAtOpen: false, today: today, now: t(2))
        #expect(try #require(habits[id]).name == "Run")
        #expect(try #require(habits[id]).days(today: today) == [fri])
    }

    // MARK: Existence

    @Test func deletedHabitsNeverInAll() {
        var habits = Habits()
        let id = habits.add(draft("Run", days: [fri]), today: oct(1), now: t(0))
        habits.delete(id, now: t(1))
        #expect(habits.all.isEmpty)
        #expect(habits.records.count == 1)
        #expect(habits.dueOn(oct(23)).isEmpty)
    }
}
