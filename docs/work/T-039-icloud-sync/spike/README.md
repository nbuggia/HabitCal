# Spike: can HabitCal sync through CloudKit as distributed (Developer ID, sandboxed, no network entitlement)?

## Question

D-010 chose CloudKit. Before designing on it (FM-012), on the customer's Mac (macOS 27, Xcode 27.1, team NETORION LLC, LZ2695932J):

1. Does a sandboxed app reach the private database with CloudKit, both development-signed and signed with Developer ID?
2. Does it need `com.apple.security.network.client`, which D-007 rules out?
3. How does it behave with no usable iCloud account (signed out, or HabitCal's iCloud switch off)?
4. Does `CKSyncEngine` start?

Build: `CloudSpike.xcodeproj` (one target, bundle ID `com.muchfiner.HabitCal.cloudspike`, container `iCloud.com.muchfiner.HabitCal`, entitlements in `CloudSpike.entitlements`). Development: `xcodebuild -project CloudSpike.xcodeproj -scheme CloudSpike -allowProvisioningUpdates build`. Every check runs on launch and is logged to `~/Library/Containers/com.muchfiner.HabitCal.cloudspike/Data/spike.log`.

## Answer (so far, 2026-10-31)

- **Q1, development-signed: yes.** Account available, user record ID read, a custom zone and a record saved, the record read back unchanged, the zone deleted.
- **Q2: no network entitlement needed.** The app has `network.client=false` and the round trip still worked: CloudKit traffic goes through the system, so D-007's no-network rule can stay.
- **Q4: yes.** `CKSyncEngine` started and `fetchChanges()` succeeded with no saved state.
- **Setup facts:**
  - Xcode's automatic provisioning registered the container (and this Mac, with the customer's OK).
  - A new container took about a minute to reach CloudKit's servers. Before that, every call failed with CKError 5, "Couldn't get container configuration from the server".
  - The development build gets `aps-environment` (push), which `CKSyncEngine` uses to hear about changes from the other Mac.
- **Q1, Developer ID: not answered yet.** The archive succeeds, but exporting it for Developer ID fails with "No Accounts" / "No profiles for 'com.muchfiner.HabitCal.cloudspike' were found". Xcode won't create a Developer ID provisioning profile with this account from the command line. Creating Developer ID profiles needs the team's Account Holder or Admin role, which may be the cause.
- **Q3: only "available" seen.** Signed-out and iCloud-switch-off behavior still needs a run with HabitCal's iCloud switch turned off in System Settings.

Known for the design, not yet seen here:
- A Developer ID build talks to CloudKit's **production** environment. Its record types exist only once the development schema is deployed to production in the CloudKit Console, so that's a release step for T-005.

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
