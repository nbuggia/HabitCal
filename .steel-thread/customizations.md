# Customizations

Changes this project made to Steel Thread's framework files and skills, and why. The st-update skill reads this to keep them when it merges a new Steel Thread version. Newest first.

## 2026-11-14 · Steel Thread 0.16.0 → 0.24.0

Merged the new version into every customized file. Kept all of the stack changes from 2026-10-29. Dropped nothing.

- `.steel-thread/framework/development.md`: took the new sizing rules (size by what a change touches; a product-rule change is never Trivial), the commit rules, and the review budget. Kept the HabitCal Testing table: Swift Testing, XCUITest, and their commands.
- `.claude/skills/st-crit/SKILL.md`: took the new review flow. The tech design reviewer is still a principal macOS engineer.
- `.claude/skills/st-design/SKILL.md`: took the new reviewer framing (spec-anchored findings, IDEAs, follow the surrounding code's patterns, no conventions file). Kept the macOS engineer persona in it.
- `.claude/skills/st-design/design-red-flags.md`: took the new version. Kept the HabitCal stack red flags.
- `.claude/skills/st-design/templates/complex-tech-design-template.md`: took the new version. Kept HabitCal's §7–§10 (interfaces, `habits.json` persistence, sandbox, macOS Versions and Appearance).

## 2026-10-29 · st-dev-setup for Swift/SwiftUI macOS

- `.claude/skills/st-design/SKILL.md`: the design reviewer is a principal macOS engineer (Swift 6, SwiftUI, AppKit menu bar apps, App Sandbox, notarization), so reviews ask this stack's questions.
- `.claude/skills/st-crit/SKILL.md`: same expert for tech design reviews.
- `.claude/skills/st-design/templates/complex-tech-design-template.md`: §7 names HabitCalKit, `AppModel`, and the macOS APIs as the interfaces; §8 names `habits.json`/`UserDefaults` and D-004's versioning; §9 names the sandbox entitlements and `SMAppService`; §10 "Cross-Platform" became "macOS Versions and Appearance", since the product ships on macOS only.
- `.claude/skills/st-design/design-red-flags.md`: added the HabitCal stack red flags (dates as instants, rules in the app target, a second writer of the data file, off-main UI state).
- `.steel-thread/framework/development.md`: the Testing table names Swift Testing, XCUITest, and their commands.
- `.claude/skills/st-slice/tech-design-slices-template.md`: the test gate names the test commands.

