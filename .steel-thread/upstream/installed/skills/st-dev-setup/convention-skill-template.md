---
name: [area]-guidelines for area guidelines, or [verb]-[thing] for a recipe; never starting with st-
description: [What it covers and when to load it, in the words a task would use. Guidelines: "Rules for UI code in src/ui/. Load before any UI change." Recipe: "Add a feature flag. Use when gating a change behind a flag."]
---

# \[Name\]

\[One line: what this covers and what it doesn't. Name the convention skill for each neighboring area.\]

\[A convention skill is one of two kinds. **Area guidelines** are the rules for one area of the code: keep Rules and Red Flags. A **recipe** is the steps for one recurring kind of change: keep Steps and Check. Delete the other two sections. Put this project's paths in examples, not in the rules themselves, so the skill can be copied to another project on the same stack.\]

## Rules

- \[One rule per line, written as an instruction, with an example file that follows it, and the D-NNN behind it when there is one.\]

## Red Flags

- \[Signs in a diff that a rule is about to be broken.\]

## Steps

1. \[Each file to touch, in order, and what changes there. Cite a commit that followed these steps.\]

## Check

- \[The test or command that proves the change worked.\]
