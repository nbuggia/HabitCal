# .steel-thread/customizations.md — Format and Rules

The record of what this project changed in Steel Thread's framework files and skills, and why. The st-update skill reads it to tell a deliberate change from an outdated one when it merges a new Steel Thread version.

## Format

```markdown
# Customizations

## .claude/skills/st-design/templates/complex-tech-design-template.md · 2026-10-18

Renamed Interface Contract to Tauri Commands & Events, and added a Capabilities row for each new command. Every feature here crosses the Rust/WebView boundary (st-dev-setup).
```

## Rules

- One entry per file per change, newest first, headed with the file's path from the project root and the date.
- Say what changed and why, in one to three lines. The why is what lets a later merge keep the change; cite the decision or the skill behind it.
- When a later change undoes an earlier one, add a new entry saying so; never edit or delete old entries.
