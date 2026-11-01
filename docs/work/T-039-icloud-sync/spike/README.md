# Spike: can HabitCal sync through CloudKit as distributed (Developer ID, sandboxed, no network entitlement)?

## Question

D-010 chose CloudKit. Before designing on it (FM-012), on the customer's Mac (macOS 27, Xcode 27.1, team NETORION LLC, LZ2695932J):

1. Does a sandboxed app reach the private database with CloudKit, both development-signed and signed with Developer ID?
2. Does it need `com.apple.security.network.client`, which D-007 rules out?
3. How does it behave with no usable iCloud account (signed out, or HabitCal's iCloud switch off)?
4. Does `CKSyncEngine` start?

Build: `CloudSpike.xcodeproj` (one target, bundle ID `com.muchfiner.HabitCal.cloudspike`, container `iCloud.com.muchfiner.HabitCal`, entitlements in `CloudSpike.entitlements`). Development: `xcodebuild -project CloudSpike.xcodeproj -scheme CloudSpike -allowProvisioningUpdates build`. Every check runs on launch and is logged to `~/Library/Containers/com.muchfiner.HabitCal.cloudspike/Data/spike.log`.

## Answer (2026-10-31)

- **Q1, development-signed: yes.** Account available, user record ID read, a custom zone and a record saved, the record read back unchanged, the zone deleted.
- **Q2: no network entitlement needed.** The app has `network.client=false` and the round trip still worked: CloudKit traffic goes through the system, so D-007's no-network rule can stay.
- **Q4: yes.** `CKSyncEngine` started and `fetchChanges()` succeeded with no saved state.
- **Setup facts:**
  - Xcode's automatic provisioning registered the container (and this Mac, with the customer's OK).
  - A new container took about a minute to reach CloudKit's servers. Before that, every call failed with CKError 5, "Couldn't get container configuration from the server".
  - The development build gets `aps-environment` (push), which `CKSyncEngine` uses to hear about changes from the other Mac.
- **Q1, Developer ID: yes.** Signed with the keychain's Developer ID Application certificate (expires 2027-02-01) and a Developer ID profile with iCloud, made at developer.apple.com, the app reached CloudKit's **production** environment:
  - account available, user record ID read, and a custom zone saved;
  - saving a record failed only with CKError 12, "Cannot create new type SpikeHabit in production schema", as expected.
  - Record types have to be deployed from development to production in the CloudKit Console before release. HabitCal's real types get deployed in T-005. The spike's type is never deployed, so no junk type ends up in production.
  - Xcode's command-line export couldn't create the Developer ID profile ("No Accounts"), so for now the release build is signed by hand with a downloaded profile. NETORION LLC has two Developer ID Application certificates; only the one expiring 2027-02-01 has its private key on this Mac, so profiles must name that one.
- **Q3: only "available" seen; the rest is an accepted risk.**
  - CloudSpike doesn't appear in System Settings' list of apps using iCloud (customer, 2026-11-01), even after its records were saved. So there was no per-app switch to turn off.
  - Signing out of iCloud on the customer's Mac wasn't worth the disruption.
  - The design treats every status but `available` the same way: keep working locally, sync later. That's covered by tests against a stand-in for CloudKit, plus a manual check on a spare Mac or test account before release.


Log excerpt (development build, second attempt):

```
Q2 entitlements: com.apple.security.network.client=false
Q3 accountStatus: available
Q3 userRecordID: _313fcb468b0…
Q1 zone saved
Q1 record saved: 1 result(s), ok
Q1 record fetched back: name=Push-ups checkOffs=["2026-10-30", "2026-10-31"]
Q1 zone deleted. CloudKit round trip OK.
Q4 CKSyncEngine fetchChanges OK
```
