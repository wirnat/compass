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

## Optional Fields

Add these only when they help a reader or agent choose the right note.

### `summary`

One line saying what question the note answers. The Compass docs index (`scripts/docs-index.sh` in the Compass skill) shows it so agents can pick notes without opening them. When it is missing, the index falls back to the first `#` heading, which is often too generic for hub notes.

### `code`

Globs, relative to the project root, for the code area this note owns. Use it on module and architecture notes so an agent can go from a file it is about to change to the notes that govern it. The docs index warns when a glob matches no files.

```yaml
summary: Billing rules for invoices, refunds, and payment retries.
code:
  - src/billing/**
```

## Avoid

- large metadata blocks that are rarely maintained
- fields containing long paragraphs
- lifecycle statuses that are too specific
- tags that replace folder structure and hub notes
- many custom fields for only one note
- hand-maintained index or manifest files that repeat frontmatter
