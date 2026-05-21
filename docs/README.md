# Documentation Ecosystem

The `docs/` folder is the entry point for project knowledge. Its job is not to collect every thought in one place, but to organize knowledge so each document has a clear purpose, location, and boundary.

The most common documentation problem is not the absence of documents. It is documentation that has no clear home, mixes too many purposes, repeats the same topic, or is no longer trusted.

## Taxonomy Principles

### One Document, One Job

Each document should answer one primary kind of question. If a file starts answering too many kinds of questions, split it.

### One Source Of Truth

The same topic must not have multiple primary sources. Other documents may reference, summarize, or apply that topic, but the source of truth must remain clear.

### Location Carries Meaning

A document location should help readers predict its content and role. Folders are part of the knowledge architecture.

### Documentation Grows Gradually

Start with a small set of clear categories. Add a new category only when the existing ones are truly insufficient.

## Base Structure

```text
docs/
  foundation/
  architecture/
  decisions/
  modules/
  process/
  runbooks/
  reference/
  _templates/
```

## Document Categories

- `foundation/`: durable principles and philosophy.
- `architecture/`: system shape, boundaries, dependency direction, and high-level structure.
- `decisions/`: long-lived engineering decisions with context, options, rationale, and consequences.
- `modules/`: specific business capabilities, components, domains, packages, or bounded areas.
- `process/`: how the team builds, reviews, tests, and ships work.
- `runbooks/`: concrete operational procedures.
- `reference/`: lookup-oriented schemas, glossary, contracts, and naming rules.
- `_templates/`: reusable note shapes.

## Placement Rules

Ask these questions before creating a new document:

1. What kind of question does this document answer?
2. Who is the primary reader?
3. What is the source of truth for this topic?
4. When should this document be updated?

If the answers are unclear, the document is usually not ready.

## Document Status

- `draft`: still evolving and not yet the primary reference
- `active`: valid and used as an active reference
- `superseded`: previously valid, but replaced by another document
- `archived`: kept for history, not used as working guidance

## Naming Convention

- `README.md` is used as a folder entry point
- topical documents use `kebab-case.md`
- decision documents use `NNNN-decision-title.md`
- document content, headings, aliases, file names, and folder names use clear technical English
