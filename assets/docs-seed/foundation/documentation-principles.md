---
type: foundation
status: active
owner: architecture
created: 2026-05-19
updated: 2026-05-19
parent: "[[docs/foundation/README]]"
tags:
  - docs/foundation
  - status/active
aliases:
  - documentation principles
related:
  - "[[docs/README]]"
  - "[[docs/reference/note-schema]]"
---

# Documentation Principles

Documentation is part of project architecture, not an appendix after technical work is finished. It helps the project keep direction, preserve decisions, and reduce the cost of rethinking when the system grows.

## Summary

Good documentation:

- has a clear purpose
- has a clear location
- has a clear owner
- has a clear relationship to other documents
- stays alive as the system changes

## Core Principles

### Documentation Is A Knowledge System

Documents do not stand alone. Documentation quality is determined by how files are connected, separated, and maintained.

### One Document, One Job

Each document should answer one primary kind of question.

### One Topic, One Source Of Truth

Every important topic must have one primary reference location. Other documents may reference, summarize, or apply that topic, but they must not become competing sources of truth.

### Taxonomy Matters More Than Volume

Adding a new document is easy. Maintaining relationships between documents is the real cost.

### Metadata Should Stay Lightweight

Frontmatter should be short, consistent, and sufficient to explain status, type, parent, and important relationships.

### Links Must Carry Meaning

Use a link when there is a real relationship: parent, related decision, definition reference, or companion document that should be read together.

### Documents Should Age Gracefully

Not every document lasts forever. Lifecycle must be clear: `draft`, `active`, `superseded`, or `archived`.

## Anti-Patterns

- creating a new file for every idea without checking the existing source of truth
- mixing principles, tutorials, decisions, checklists, and references in one note
- assuming every document must appear in the root README
- using tags as a replacement for folder structure and hub notes
- writing so much metadata that it stops being maintained
- leaving old documents active after they have been replaced
