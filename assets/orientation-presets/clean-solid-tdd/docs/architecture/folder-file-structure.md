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
  - folder architecture
  - file architecture
  - project structure
related:
  - "[[docs/architecture/clean-architecture]]"
  - "[[docs/foundation/solid-principles]]"
  - "[[docs/process/tdd-workflow]]"
---

# Folder And File Structure

This document defines the default folder and file shape for projects using the `clean-solid-tdd` Compass preset.

The structure is intentionally explicit. Humans are busy, agents are literal, and both benefit from a map. Without a map, every road eventually leads to `utils`.

## Principles

- `internal/` is the private application boundary when the language supports it.
- Main boundaries are separated by business module and shared platform capability.
- Business rules and usecases are separated from transport and persistence details.
- One file should have one primary reason to change.
- Create folders lazily when real behavior, a real contract, or a real implementation needs a home.
- Documentation, comments, file names, and folder names use clear technical English.

## Base Project Structure

```text
project/
├── cmd/
│   ├── README.md
│   └── api/
│       └── main.go
├── internal/
│   ├── app/
│   │   ├── README.md
│   │   ├── bootstrap.go
│   │   └── routes.go
│   ├── platform/
│   │   ├── README.md
│   │   ├── config/
│   │   ├── db/
│   │   ├── http_server/
│   │   ├── logger/
│   │   ├── request_ctx/
│   │   ├── clock/
│   │   └── idgen/
│   ├── shared_kernel/
│   │   ├── README.md
│   │   └── <shared_value>/
│   └── modules/
│       ├── README.md
│       └── <module>/
├── docs/
│   ├── architecture/
│   ├── foundation/
│   ├── decisions/
│   ├── modules/
│   ├── process/
│   ├── runbooks/
│   ├── reference/
│   └── _templates/
└── scripts/
    ├── README.md
    └── <category>/
```

For Go projects, add `go.mod` at the project root. For other stacks, keep the same boundary intent and adapt only the language-specific entrypoints and package conventions.

## Structural README Files

Stable top-level code folders should include a local `README.md` that explains:

- the folder objective
- protected boundaries
- responsibilities
- what belongs there
- what does not belong there
- likely future growth

These README files are navigation aids. They do not replace [[docs/architecture/clean-architecture]] or [[docs/process/tdd-workflow]].

## Folder Framework Change Control

The base project structure is a framework boundary and should rarely change. Routine feature work must grow inside the existing folders instead of creating parallel structures.

Allowed implementation growth:

- add a new command under `cmd/` when a new deployable process is required
- add a new business module under `internal/modules/` when real business behavior needs a home
- add documented module layer folders under `internal/modules/<module>/`
- add a focused technical capability under `internal/platform/` when it belongs to shared infrastructure
- add a stable shared domain value under `internal/shared_kernel/` only when at least two modules need it
- add docs under the existing `docs/` taxonomy
- add shared automation under `scripts/<category>/`

Framework changes require explicit direction and documentation updates. Examples:

- new root-level folders
- new `internal/` peer folders
- renaming established folders
- moving module layers
- introducing competing names such as `services`, `repositories`, `delivery`, `handlers`, `usecases`, `common`, `utils`, or `pkg`

When a folder change is necessary, update this architecture note, any local `README.md`, and the related decision or process note. Do not let code and documentation quietly diverge.

## Scripts Structure

Use `scripts/` for shared repository automation, not business behavior or runtime application logic.

```text
scripts/
├── README.md
└── <category>/
    └── <script>.sh
```

Each child folder should represent a stable automation category, such as `git_hooks/`, `db/`, or `codegen/`.

Scripts that change local machine state, Git hooks, generated files, staged content, or external services must be documented in a runbook or `scripts/README.md`.

## Business Module Structure

Use this target shape for each active business module:

```text
internal/modules/<module>/
├── README.md
├── domain/
│   ├── <module>.go
│   ├── errors.go
│   └── policy.go
├── usecase/
│   ├── <simple_operation>.go
│   └── <complex_operation>/
│       ├── dto.go
│       ├── ports.go
│       ├── usecase.go
│       └── usecase_test.go
├── adapters/
│   ├── http/
│   │   ├── handler.go
│   │   ├── request.go
│   │   ├── response.go
│   │   └── routes.go
│   ├── postgres/
│   │   ├── repository.go
│   │   ├── <module>_model.go
│   │   └── mapper.go
│   ├── memory/
│   │   └── repository.go
│   ├── <technical_adapter>/
│   │   └── adapter.go
│   └── <bridge>/
│       └── adapter.go
└── module.go
```

This is the target shape for active modules, not permission to create empty folders ahead of time.

## Module README

Each module should have `README.md` once it has real behavior.

The module README should include:

- responsibility
- main usecases
- boundary
- rules
- owned adapters
- future exclusions
- related docs

Do not use module README as a dumping ground for implementation notes that belong in architecture, process, or decision docs.

## Module Layer Responsibilities

### `domain`

`domain` contains pure business concepts and rules. It owns entities, value objects, validation policies, invariants, and domain errors.

`domain` must not import:

- `usecase`
- `adapters`
- `internal/platform`
- HTTP packages
- ORM packages
- database packages
- external provider clients

### `usecase`

`usecase` contains application-specific orchestration. It coordinates domain behavior, handles branching, defines input and output DTOs, and declares narrow ports required by the usecase.

Use flat files under `usecase/` only for small operations with simple DTOs, few dependencies, and small tests.

Create `usecase/<operation>/` when an operation has:

- its own DTOs
- local ports
- branching
- non-trivial test setup
- enough code that a single flat file becomes hard to scan

Operation packages are still part of the usecase layer. They are not a new architecture layer.

### `adapters/http`

`adapters/http` contains HTTP transport mapping:

- route registration
- handlers
- request parsing
- transport-level validation
- response mapping
- HTTP status code decisions

HTTP adapters call usecases. They must not contain domain rules or persistence logic.

### `adapters/postgres`

`adapters/postgres` contains Postgres-specific persistence implementation:

- SQL or ORM-specific models
- query implementation
- transaction behavior
- persistence mapping
- database error translation

Postgres adapters implement usecase ports. They must not define business rules, own usecase contracts, or leak ORM models into `domain` or `usecase`.

### `adapters/memory`

`adapters/memory` contains in-memory implementations for proof-of-concept flows, local development, or focused tests.

Memory adapters must not become hidden production persistence. When durability, concurrency guarantees, or cross-process state matters, add a real infrastructure adapter.

### `adapters/<technical_adapter>`

Use module-specific technical adapters for capabilities such as password hashing, token issuing, provider clients, file generation, or other concrete dependencies that carry module-specific vocabulary.

Use `internal/platform` only for shared technical primitives that are stable across modules and do not own business behavior.

### `adapters/<bridge>`

Use bridge adapters for explicit collaboration between modules through small snapshots or contracts.

Bridge adapters must avoid importing another module's raw domain model directly into the consumer module.

### `module.go`

`module.go` wires the module's repositories, usecases, handlers, and route registration.

`module.go` is the only place inside a module that should know how the module's concrete adapters are assembled for the default application runtime.

## Recommended Import Contract

1. `adapters/http` imports `usecase`.
2. `adapters/postgres` imports `usecase` and implements usecase contracts.
3. `usecase` imports `domain`.
4. `module.go` imports adapters and usecase to perform dependency injection.
5. `internal/app` imports modules through small composition surfaces.

The goal is to keep dependency direction pointing inward.

## Naming Convention

Use clear technical English for folder and file names.

For multi-word conceptual boundary folders, prefer `snake_case` in folder names, such as:

- `http_server`
- `request_ctx`
- `shared_kernel`

Language package names may remain idiomatic. In Go, a folder such as `http_server` may expose package `httpserver` when that makes imports cleaner.

## Common File Names

Use conventional names so readers do not have to solve a riddle:

- `errors.go` for domain or usecase error definitions
- `policy.go` for rule groups and policies
- `dto.go` for usecase input/output DTOs
- `ports.go` for consumer-side interfaces
- `usecase.go` for orchestration
- `handler.go` for HTTP handler behavior
- `request.go` for transport input parsing
- `response.go` for transport output mapping
- `routes.go` for route registration
- `repository.go` for persistence adapter implementation
- `<module>_model.go` for persistence models
- `mapper.go` for persistence/domain/usecase mapping
- `module.go` for module composition

## Folder Creation Gate

Before creating a folder, classify it:

- `implementation growth`: fits this documented structure and has real behavior, contract, or implementation.
- `framework change`: introduces a new root area, new `internal/` peer area, new layer name, or competing architecture pattern.

Proceed with implementation growth. Stop on framework change unless the user explicitly requested an architecture change and the relevant docs are updated.

## Anti-Patterns

- Empty folders created because the architecture diagram had boxes.
- Parallel layer names such as `services`, `repositories`, `delivery`, or `handlers`.
- Generic `common`, `helper`, `utils`, or `pkg` folders.
- Business rules in HTTP handlers.
- ORM tags in domain entities.
- Usecase packages importing Postgres, HTTP, or platform implementations.
- Module-specific route details in `internal/app/routes.go`.
- Shared kernel used as a drawer for random conveniences.

## Completion Evidence

When a feature adds folders or files, Compass should report:

- why each new folder exists
- which documented structure it fits
- which test proves the behavior or boundary
- whether any architecture docs changed
- whether dependency direction stayed inward
