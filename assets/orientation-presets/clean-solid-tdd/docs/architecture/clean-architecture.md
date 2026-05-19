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
  - clean architecture
  - dependency rule
related:
  - "[[docs/architecture/folder-file-structure]]"
  - "[[docs/foundation/solid-principles]]"
  - "[[docs/process/tdd-workflow]]"
  - "[[docs/decisions/0001-orientation-lock]]"
---

# Clean Architecture

This project uses Clean Architecture as the default architecture lock. The goal is not to make the code look academic. The goal is to keep business behavior clean, testable, and protected from fast-changing technical details.

Clean Architecture answers one practical question: **where should dependencies point?**

The answer: source code dependencies point inward, toward stable policy and business rules. HTTP, CLI, database, queues, external APIs, frameworks, and runtime setup live near the edge.

## Research Basis

Robert C. Martin describes Clean Architecture as a synthesis of architectures that separate concerns, including Hexagonal Architecture, Onion Architecture, DCI, and BCE. The desired qualities are independence from frameworks, testability without UI/database/web server, independence from UI, independence from database, and business rules that do not know the outside world.

The central rule is the Dependency Rule: source code dependencies may only point inward. Inner layers must not mention names from outer layers, including classes, functions, variables, framework data formats, database rows, or concrete technical details.

This preset applies that rule with a pragmatic modular monolith structure. It creates modules lazily, uses manual dependency injection, and keeps adapters concrete at the edge.

## Layer Model

```text
cmd/<app>
  -> internal/app
    -> internal/modules/<module>/adapters
      -> internal/modules/<module>/usecase
        -> internal/modules/<module>/domain
```

Dependencies may move from outside to inside. The opposite direction should be avoided.

## Responsibility Map

| Area | Owns | Must not own |
| --- | --- | --- |
| `cmd/<app>` | process entrypoint, signal handling, fatal startup reporting | business rules, route details, persistence logic |
| `internal/app` | application bootstrap, dependency wiring, top-level route composition | module-specific business rules, database models, request parsing |
| `internal/platform` | shared technical primitives such as config, logger, DB connection, clock, ID generator, server setup | business behavior or module vocabulary |
| `internal/shared_kernel` | stable shared domain values used by multiple modules | generic helpers, infrastructure details, response wrappers |
| `internal/modules/<module>/domain` | entities, value objects, invariants, policies, business errors | HTTP, DB, framework, platform, external API details |
| `internal/modules/<module>/usecase` | application orchestration, DTOs, consumer-side ports, branching | concrete repositories, HTTP handlers, ORM models |
| `internal/modules/<module>/adapters/http` | route registration, handlers, request parsing, response mapping, HTTP status | domain rules, persistence logic |
| `internal/modules/<module>/adapters/postgres` | SQL/ORM models, persistence mapping, query implementation | usecase contracts, business rules, HTTP response mapping |
| `internal/modules/<module>/adapters/memory` | proof-of-concept or focused test implementations | hidden production persistence |
| `internal/modules/<module>/module.go` | module-level composition | serious technical implementation or business rules |

## Domain

Domain contains the most stable business rules:

- entities and value objects
- invariants
- business policies
- business errors
- calculations and validation rules
- behavior testable without HTTP, database, queue, framework, or external services

Domain must not import:

- HTTP handlers or request objects
- ORM or SQL drivers
- concrete loggers
- runtime config
- framework context or request context
- response DTOs
- database models
- adapter packages
- platform packages

If domain needs time, IDs, money, or external decisions, pass values in or define a small contract in the consumer layer. Do not smuggle infrastructure into domain because "it is only one import". One import grows into a family reunion.

## Usecase

Usecase contains application-specific orchestration:

- scenario validation
- branching
- conceptual transactions
- calls to ports, repositories, clocks, ID generators, or external capabilities through small interfaces
- mapping application input to domain and application output

Usecase may import domain and standard-library packages. Usecase must not import concrete adapters, HTTP frameworks, ORM models, database drivers, or external API clients.

Interfaces for dependencies are defined on the usecase side, because the consumer owns what it needs. For a small operation, ports may live in `usecase/ports.go`. For a larger operation, keep DTOs, ports, usecase, and tests together under `usecase/<operation>/`.

## Adapters

Adapters translate outside formats into shapes that are comfortable for usecase/domain, and back again.

Adapter examples:

- HTTP request and response mapping
- CLI command parsing and output formatting
- database rows, ORM models, and SQL mapping
- external API payload mapping
- queue message parsing
- file or storage format conversion

Adapters may contain technical details as long as the details stop at the boundary. SQL, ORM tags, HTTP status codes, JSON tags, headers, provider payloads, and framework objects must not leak into domain or usecase.

## Platform

Platform contains shared technical implementations:

- config loading
- structured logging
- database connection setup
- HTTP server setup
- clock implementation
- ID generation
- request context extraction

Platform packages must not import business modules. They provide tools, not policy.

When a usecase needs a platform capability, define the narrow port where the usecase needs it. Then let a platform implementation or module adapter satisfy the port during composition.

## Shared Kernel

Shared kernel is reserved for stable domain concepts used by multiple modules, such as `money`, `email`, or other value objects with clear invariants.

Do not use shared kernel as a polite name for `common`, `helper`, `utils`, response wrappers, logging shortcuts, or formatting conveniences.

Move a concept into shared kernel only when:

- at least two modules need the same concept
- the invariants are stable
- the concept is free from infrastructure concerns
- the concept's name belongs to the domain, not to a framework

## Cross-Module Dependency Rules

- Business modules must not import another module's raw domain package for core flows.
- Business modules must not depend on another module's internal usecase implementation.
- If a module needs read-only data from another module's table, keep that query inside the consumer module's persistence adapter and document the schema dependency with tests.
- If a module needs another module's rule or invariant, do not duplicate it with SQL. Define a clear contract for the decision or revisit the module boundary.
- Bridge adapters may translate through small snapshots or contracts, but they must not become a shortcut to bypass boundaries.

## Dependency Direction Examples

Allowed:

```text
internal/modules/order/adapters/http
  imports internal/modules/order/usecase

internal/modules/order/adapters/postgres
  imports internal/modules/order/usecase

internal/modules/order/usecase
  imports internal/modules/order/domain
```

Avoid:

```text
internal/modules/order/domain
  imports internal/modules/order/adapters/postgres

internal/modules/order/usecase
  imports github.com/example/httpframework

internal/modules/order/domain
  imports gorm.io/gorm

internal/modules/order/usecase
  imports internal/platform/db
```

## Dependency Injection

Use manual dependency injection by default.

Dependency injection is split into two levels:

- `internal/app` wires application-level dependencies such as config, logger, database connections, clock, ID generator, and active modules.
- `internal/modules/<module>/module.go` wires module-level repositories, usecases, handlers, and route registration.

Do not introduce a dependency injection container until the dependency graph becomes large enough that manual wiring creates proven maintenance friction.

`internal/app` should depend on each active module through a small composition surface, such as route registration. It should not know module-specific HTTP paths, handler methods, repository details, or usecase construction internals.

## Route Composition

`internal/app/routes.go` is the top-level route composer. It may register application-level routes such as `/healthz` and mount active module routes through a small contract.

Example:

```go
type RouteRegistrar interface {
	RegisterRoutes(mux *http.ServeMux)
}
```

Business modules satisfy this contract from `module.go` without importing `internal/app`. Module-specific route paths, HTTP handlers, request parsing, and response mapping stay inside `internal/modules/<module>/adapters/http`.

Do not place module-specific route details directly in `internal/app/routes.go`.

## Testing And Evidence

- Domain tests prove invariants and policies without infrastructure.
- Usecase tests prove orchestration with small fake ports.
- Adapter tests prove request parsing, response mapping, persistence mapping, and external payload mapping.
- Integration tests prove real infrastructure assumptions.
- End-to-end tests are reserved for important flows that cannot be proven cheaply at a lower level.

If a test needs a database to prove a pure business rule, the boundary is probably leaking. The database is useful, but do not ask it to explain multiplication to a child.

## Anti-Patterns

- Creating `common`, `helper`, `utils`, `service`, `repository`, `handler`, or `delivery` as competing architecture folders.
- Putting every contract in a global `ports` package.
- Creating repository interfaces inside Postgres adapters.
- Adding ORM tags to domain entities.
- Passing framework request objects into domain or usecase.
- Testing business rules only through HTTP or database tests.
- Creating empty module folders before behavior exists.
- Adding a dependency injection container before manual wiring hurts.
- Duplicating another module's rule in SQL.
- Equating Clean Architecture with the number of folders.

## Review Checklist

- Do dependencies still point inward?
- Is domain free from HTTP, ORM, database rows, frameworks, runtime config, and platform packages?
- Does usecase define small consumer-side ports instead of importing concrete implementations?
- Does each adapter translate outside formats and call usecase?
- Is each interface created because a consumer needs it?
- Does every file have a clear reason to change?
- Is each test at the cheapest level that still proves behavior?
- Are new folders backed by real behavior, contracts, or implementations?
- Is documentation updated when a boundary or principle changes?

## External References

- Robert C. Martin, "The Clean Architecture": https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- Robert C. Martin, "The Clean Architecture Dependency Rule": https://www.informit.com/articles/article.aspx?p=2832399
- Alistair Cockburn, "Hexagonal Architecture": https://alistair.cockburn.us/hexagonal-architecture
- Microsoft Learn, "Common web application architectures": https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures
