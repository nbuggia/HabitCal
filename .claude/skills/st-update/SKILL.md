---
name: st-update
description: Merge a new Steel Thread version into the framework files and skills this project has customized, keeping the project's changes. Use after the Steel Thread installer reports customized files that need merging, or when the customer asks to update Steel Thread.
---

The installer updates every Steel Thread file the project hasn't changed. It never overwrites a customized one; it leaves the new version for you to merge. Your job is a three-way merge done with judgment: bring in what Steel Thread changed, keep what the project changed, and say what you did.

## Step 1 — Find what needs merging

Read `.steel-thread/upstream/incoming/PENDING`. If it doesn't exist, there is nothing to merge. If the customer asked to update Steel Thread, tell them to run the installer from their Steel Thread clone first (`path/to/steel-thread/install.sh`), then run this skill again.

PENDING is tab-separated. The `from` and `to` lines give the versions. Every other line is one file: its kind, its path in Steel Thread, and its path in this project. For each file, three versions may exist:

- **Base** — `.steel-thread/upstream/installed/<Steel Thread path>`: the Steel Thread version the project's copy started from. Missing for projects installed before base files were kept.
- **New** — `.steel-thread/upstream/incoming/<Steel Thread path>`: the new Steel Thread version.
- **Local** — the project's copy, at the project path.

## Step 2 — Understand both sides

Read before you merge: `.steel-thread/customizations.md`, for why the project changed each file, and Customizing Steel Thread in `.steel-thread/framework/steel-thread.md`, for the formats a merged file must keep.

## Step 3 — Merge each file

Work out Steel Thread's change from base to new (`diff -u base new`), and the project's change from base to local. Read Steel Thread's change as a whole and work out what it is for, since that intent is what you carry into text that no longer matches. Then:

- **modified** — both sides changed it. Apply Steel Thread's change to the local file, keeping the project's customizations. Where they touch the same text, carry Steel Thread's intent into the project's wording rather than replacing it. Without a base, compare new against local: a difference explained in customizations.md is the project's; treat any other as Steel Thread's, and say so in your report.
- **removed** — Steel Thread no longer ships this file, but the project customized it. Look in the other new files for where its job went, such as a renamed skill or a merged section. Delete the file if its job moved elsewhere, and carry the project's customizations to the replacement. Keep it if the project still relies on it.
- **deleted** — the project deleted this file, and Steel Thread has since changed it. Leave it deleted unless the change fixes something this project still relies on.

When the new version changes a format other files read, such as a heading or a frontmatter field, update every customized file that depends on it, not only the pending ones.

A conflict is a high-judgment decision only when keeping the project's change would lose a fix or a rule Steel Thread clearly added on purpose, or taking Steel Thread's would undo something customizations.md says the project chose on purpose. Ask about those, together, with your recommendation for each. Decide the rest yourself.

## Step 4 — Finish

After each file is resolved:

- Copy its new version from `incoming/` to the same path in `installed/`, so the next update compares against it. For a resolved **removed** file, delete its base from `installed/` instead.
- Log every file you changed in `.steel-thread/customizations.md`: what you merged, and anything of the project's that you dropped and why.

When every file is resolved, delete `.steel-thread/upstream/incoming/`. Then report in a few lines: what you adopted, what you adapted to the project's customizations, what you skipped and why, and any question still open.
