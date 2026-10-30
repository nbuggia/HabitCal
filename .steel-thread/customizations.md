# Customizations

Changes this project made to Steel Thread's framework files and skills, and why. The st-update skill reads this to keep them when it merges a new Steel Thread version. Newest first.

## 2026-10-29 · st-dev-setup for Swift/SwiftUI macOS

- `.claude/skills/st-design/SKILL.md`: the design reviewer is a principal macOS engineer (Swift 6, SwiftUI, AppKit menu bar apps, App Sandbox, notarization), so reviews ask this stack's questions.
- `.claude/skills/st-crit/SKILL.md`: same expert for tech design reviews.
- `.claude/skills/st-design/templates/complex-tech-design-template.md`: §7 names HabitCalKit, `AppModel`, and the macOS APIs as the interfaces; §8 names `habits.json`/`UserDefaults` and D-004's versioning; §9 names the sandbox entitlements and `SMAppService`; §10 "Cross-Platform" became "macOS Versions and Appearance", since the product ships on macOS only.
- `.claude/skills/st-design/design-red-flags.md`: added the HabitCal stack red flags (dates as instants, rules in the app target, a second writer of the data file, off-main UI state).
- `.steel-thread/framework/development.md`: the Testing table names Swift Testing, XCUITest, and their commands.
- `.claude/skills/st-slice/tech-design-slices-template.md`: the test gate names the test commands.

