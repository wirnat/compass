# Note Schema

This document defines the metadata schema used by project notes so they remain human-readable, searchable, and structured enough for lightweight queries.

## Purpose

This schema protects three things:

1. every note has a clear identity
2. every note has traceable relationships
3. metadata stays lightweight and does not become administrative debt

## Core Fields

```yaml
---
type: architecture
status: draft
owner: engineering
created: 2026-05-19
updated: 2026-05-19
parent: "[[docs/architecture/README]]"
tags:
  - docs/architecture
  - status/draft
aliases:
related:
---
```

### `type`

Initial values:

- `hub`
- `foundation`
- `architecture`
- `decision`
- `module`
- `process`
- `runbook`
- `reference`

### `status`

Initial values:

- `draft`
- `active`
- `superseded`
- `archived`

### `owner`

The primary owner of the note or area.

### `created` And `updated`

Use `YYYY-MM-DD`.

### `parent`

The hub note or parent note that acts as the main entry point for this note.

### `tags`

Use tags for cross-folder facets, not as a replacement for taxonomy.

Initial pattern:

- `docs/<category>`
- `status/<status>`

### `aliases`

Optional abbreviations, alternate names, or equivalent terms.

### `related`

Optional meaningful links to other notes.

## Avoid

- large metadata blocks that are rarely maintained
- fields containing long paragraphs
- lifecycle statuses that are too specific
- tags that replace folder structure and hub notes
- many custom fields for only one note
