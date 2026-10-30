# Contracts

The promises HabitCal makes to users and other systems, which must hold across every change. ARCHITECTURE.md names the component that implements each; DECISIONS.md holds why.

## ⌘Q quits

- **Promise:** while the popover is open, ⌘Q quits HabitCal.
- **Relied on by:** users' muscle memory; a Dock-less app has no other standard way to quit.
- **Versioning:** never removed.
- **Tested by:** `testCommandQQuitsWhilePopoverIsOpen`.

## About link

- **Promise:** the link in Settings opens https://www.muchfiner.com in the default browser.
- **Relied on by:** users looking for the app's home page.
- **Versioning:** change the URL only with a redirect from the old one.
- **Tested by:** manual test "The website link opens the browser" (`docs/manual-tests/menu-bar.md`).
