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
  - DDD
  - domain-driven design
related:
  - "[[docs/architecture/bounded-context-structure]]"
  - "[[docs/foundation/domain-modeling-principles]]"
  - "[[docs/process/bdd-tdd-workflow]]"
  - "[[docs/decisions/0001-orientation-lock]]"
---

# Domain-Driven Design

This project uses Domain-Driven Design when business vocabulary and behavior are complex enough to deserve explicit modeling.

DDD is not "make many folders and call them aggregates." DDD is a discipline for keeping the model close to the business language and keeping different meanings separated. If the business says "booking" but code says `DataRecordManager`, the code is already hiding the lesson under the desk.

## Research Basis

Eric Evans introduced Domain-Driven Design as a way to tackle complexity in the heart of software. Martin Fowler summarizes DDD as designing software based on models of the underlying domain. Fowler also describes Bounded Context as a central DDD pattern: large models are divided into contexts, and their relationships are made explicit.

Dan North's BDD work is compatible with DDD because behavior scenarios create a shared language for analysts, testers, developers, and the business. BDD is used here to clarify domain behavior before TDD turns it into executable evidence.

## Core Rule

Model the software around business language and protected domain boundaries.

One model does not need to describe the whole company. Each bounded context owns a consistent model for its part of the domain.

## Strategic Design

### Ubiquitous Language

Ubiquitous language is the shared vocabulary used by domain experts, product people, developers, tests, and documentation.

Compass must prefer business terms in:

- module names
- context names
- aggregate names
- value object names
- usecase names
- behavior scenarios
- test names
- error names

If the code vocabulary and business vocabulary drift apart, update one of them intentionally. Do not let translation happen silently in people's heads. Heads are not version-controlled.

### Bounded Context

A bounded context is a boundary where a domain model is internally consistent.

Rules:

- Each bounded context owns its language.
- A term may mean different things in different contexts.
- Cross-context collaboration must use explicit contracts, events, snapshots, or translation.
- Do not share raw domain entities between contexts.
- A context boundary may live inside a modular monolith before it becomes a separate service.

### Context Map

Use a context map when more than one bounded context exists.

The context map should record:

- upstream and downstream relationships
- shared kernel decisions
- published language contracts
- anti-corruption layers
- open host service boundaries
- customer/supplier relationships
- known integration risks

Do not create context-map ceremony before a second context exists.

## Tactical Design

### Entity

An entity has identity over time.

Use entities when:

- identity matters more than attributes
- the object changes over time
- behavior depends on lifecycle

Avoid entities when a value object is enough.

### Value Object

A value object is defined by its attributes and invariants, not identity.

Use value objects for:

- money
- email
- quantity
- date range
- address
- status reason
- domain-specific measurements

Value objects should validate themselves and be immutable where practical.

### Aggregate

An aggregate protects consistency rules. It has an aggregate root that controls changes inside the boundary.

Use aggregates when:

- multiple entities or values must change together
- invariants must be protected at a transaction boundary
- callers need one entry point for state changes

Avoid aggregates when:

- the object is just a data bag
- there is no consistency rule
- loading the whole aggregate would make simple behavior expensive

### Domain Service

Use a domain service only when behavior is truly domain logic but does not naturally belong to one entity or value object.

Do not create `SomethingService` because naming is hard. Naming is hard, yes; but calling everything service is like naming every child "Nak" and hoping attendance works.

### Domain Event

Use domain events to record meaningful things that happened in the domain.

Domain events should be named in past tense:

- `OrderPaid`
- `AppointmentBooked`
- `StockReserved`

Do not use domain events as a shortcut for unclear dependencies.

## Layering Inside A Context

Each bounded context may use Clean Architecture-style dependency direction internally:

```text
adapters
  -> application/usecase
    -> domain
```

The important DDD lock is context ownership:

- domain model belongs to one context
- context integration is explicit
- language is protected
- persistence and transport do not define the model

## Context Integration Rules

- Do not import another context's raw domain model.
- Use a snapshot DTO when the consumer only needs facts.
- Use a command or application contract when the consumer asks another context to do work.
- Use events when the consumer reacts to something that already happened.
- Use an anti-corruption layer when the provider model is different or legacy.
- Document every cross-context dependency in the context map or module README.

## Persistence Rules

- Persistence models must not define the domain language.
- Repository contracts belong to the consumer/application side.
- Do not let database tables decide aggregate boundaries.
- Do not load huge aggregates when a small projection is enough.
- Read models and projections are allowed when they are explicitly not domain models.

## When To Use This Preset

Use `ddd-solid-bdd` when:

- business language is complex or ambiguous
- different teams use the same words differently
- behavior depends on domain rules, not just CRUD
- invariants are important
- integration between business areas needs careful translation
- examples and scenarios are needed to clarify meaning

Do not use it just because DDD sounds senior. Seniority is knowing when not to bring a forklift to move one lunchbox.

## Review Checklist

- Can domain experts recognize the names?
- Is each business rule owned by one context?
- Are context boundaries explicit?
- Are aggregates protecting real consistency boundaries?
- Are value objects carrying meaningful invariants?
- Are events named after real domain facts?
- Are cross-context integrations documented and tested?
- Did we avoid tactical DDD patterns that the behavior has not earned?

## External References

- Eric Evans, "Domain-Driven Design: Tackling Complexity in the Heart of Software"
- Martin Fowler, "Bounded Context": https://martinfowler.com/bliki/BoundedContext.html
- Martin Fowler, "DDD Aggregate": https://martinfowler.com/bliki/DDD_Aggregate.html
- Dan North, "Introducing BDD": https://dannorth.net/blog/introducing-bdd/
