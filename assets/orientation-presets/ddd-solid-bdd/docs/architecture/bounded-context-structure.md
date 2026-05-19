---
type: architecture
status: active
owner: architecture
created: 2026-05-19
updated: 2026-05-19
parent: "[[docs/architecture/README]]"
tags:
  - docs/architecture
  - status/active
aliases:
  - bounded context structure
  - DDD folder structure
related:
  - "[[docs/architecture/domain-driven-design]]"
  - "[[docs/foundation/domain-modeling-principles]]"
  - "[[docs/process/bdd-tdd-workflow]]"
---

# Bounded Context Structure

This document defines the default folder and file shape for projects using the `ddd-solid-bdd` Compass preset.

The structure protects domain language first. Folders are not trophies. They exist only when they help humans and agents preserve meaning.

## Base Project Structure

```text
project/
|-- cmd/
|   `-- <app>/
|       `-- main.go
|-- internal/
|   |-- app/
|   |   |-- bootstrap.go
|   |   `-- routes.go
|   |-- platform/
|   |   |-- config/
|   |   |-- db/
|   |   |-- logger/
|   |   |-- clock/
|   |   `-- idgen/
|   `-- contexts/
|       |-- README.md
|       `-- <bounded_context>/
|-- docs/
|   |-- architecture/
|   |-- foundation/
|   |-- decisions/
|   |-- modules/
|   |-- process/
|   |-- reference/
|   `-- runbooks/
`-- scripts/
```

If the codebase already uses `internal/modules/`, the team may keep that name. The DDD meaning remains bounded context. Do not rename a healthy existing structure just to satisfy vocabulary.

## Bounded Context Shape

```text
internal/contexts/<bounded_context>/
|-- README.md
|-- domain/
|   |-- aggregates/
|   |   `-- <aggregate>/
|   |       |-- aggregate.go
|   |       |-- errors.go
|   |       |-- events.go
|   |       `-- policy.go
|   |-- values/
|   |   `-- <value_object>.go
|   |-- services/
|   |   `-- <domain_service>.go
|   `-- events/
|       `-- <event>.go
|-- application/
|   `-- <usecase>/
|       |-- command.go
|       |-- result.go
|       |-- ports.go
|       |-- handler.go
|       `-- handler_test.go
|-- adapters/
|   |-- http/
|   |   |-- handler.go
|   |   |-- request.go
|   |   |-- response.go
|   |   `-- routes.go
|   |-- postgres/
|   |   |-- repository.go
|   |   |-- model.go
|   |   `-- mapper.go
|   |-- events/
|   |   `-- publisher.go
|   `-- anticorruption/
|       `-- <external_context>_mapper.go
`-- context.go
```

Create folders lazily. A simple context may start with:

```text
internal/contexts/<bounded_context>/
|-- README.md
|-- domain/
|   `-- <concept>.go
|-- application/
|   `-- <usecase>.go
`-- context.go
```

Grow into the full shape only when behavior proves the need.

## Context README

Each bounded context needs a README once it has real behavior.

It should include:

- context purpose
- ubiquitous language terms
- owned aggregates
- owned value objects
- main usecases
- integration contracts
- upstream/downstream contexts
- rules and invariants
- excluded responsibilities

## Domain Folder Rules

Use `domain/aggregates` only when aggregate consistency boundaries are real.

Use `domain/values` for meaningful immutable values with invariants.

Use `domain/services` sparingly. A domain service must contain domain logic that does not belong to one aggregate or value object.

Use `domain/events` for domain facts that happened and are meaningful to other parts of the business.

Avoid:

- anemic entities with all behavior in application services
- one giant aggregate for the whole context
- domain services as a hiding place for procedural code
- value objects that only wrap strings without invariants

## Application Folder Rules

Application usecases coordinate domain behavior.

They own:

- commands or input DTOs
- result DTOs
- consumer-side ports
- transaction boundaries
- orchestration
- behavior tests

They must not own:

- domain invariants
- SQL
- HTTP status decisions
- external provider payloads
- framework request objects

## Adapter Folder Rules

Adapters translate outside formats into application commands and back out.

HTTP adapters own request/response/status mapping.

Postgres adapters own persistence mapping and database-specific behavior.

Event adapters own publish/subscribe mechanics.

Anti-corruption adapters translate external or legacy models into local context language.

## Context Map Document

When there are at least two contexts, create:

```text
docs/architecture/context-map.md
```

It should include:

- context list
- relationship type
- integration contracts
- upstream/downstream direction
- anti-corruption layer needs
- known language conflicts

## Folder Creation Gate

Before creating a DDD folder, answer:

- Which context owns this concept?
- Is this concept in the ubiquitous language?
- Is there real behavior or invariant behind it?
- Is this an aggregate, value object, domain service, application usecase, or adapter?
- Would a simpler folder shape be enough?

Stop when the answer is "because DDD says so." DDD does not say "make more folders"; DDD says "model the domain."

## Naming Rules

- Use business language for contexts, aggregates, values, events, and usecases.
- Use past tense for domain events.
- Use command-style names for application commands.
- Avoid generic names such as `Manager`, `Processor`, `Service`, `Data`, `Common`, and `Helper`.
- If the business has no word for it, inspect whether the concept is technical rather than domain.

## Completion Evidence

When a change adds DDD structure, Compass should report:

- context owner
- ubiquitous language term used
- aggregate or value invariant protected
- behavior scenario that proves the rule
- integration contract if another context is touched
- context map update if context relationships changed
