---
type: architecture
status: draft
owner: architecture
created: 2026-05-19
updated: 2026-05-19
parent: "[[docs/architecture/README]]"
tags:
  - docs/architecture
  - status/draft
aliases:
  - existing architecture
related:
  - "[[docs/decisions/0001-orientation-lock]]"
---

# Existing Architecture Lock

This project preserves the architecture already present in the codebase.

## Required Discovery

Before implementation, Compass must inspect:

- root folders and package/module layout
- existing README or architecture docs
- build and test commands
- dependency direction already used by working code
- naming conventions and composition points

## Lock Rules

- Grow inside the existing structure.
- Do not create competing layer names or root folders without an architecture decision.
- Keep new code consistent with existing tests, package boundaries, and composition style.
- When the existing structure is unclear or contradictory, document the ambiguity before changing it.

## Fill This In

- Current architecture name:
- Protected boundaries:
- Allowed folder growth:
- Disallowed competing patterns:
- Test and build commands:
