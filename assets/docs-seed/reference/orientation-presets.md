---
type: reference
status: active
owner: architecture
created: 2026-05-19
updated: 2026-05-19
parent: "[[docs/reference/README]]"
tags:
  - docs/reference
  - status/active
aliases:
  - orientation presets
  - compass presets
related:
  - "[[docs/decisions/0001-orientation-lock]]"
---

# Orientation Presets

Compass uses an orientation preset to lock the first architectural direction, engineering principles, and development workflow before feature implementation begins.

Compass must offer these presets before bootstrapping docs into a project. Do not silently apply a default preset. The only exception is `existing-architecture-lock`, which Compass may select from observed existing-project evidence when the project already has coherent architecture, conventions, and workflow that should be preserved.

The selected preset also provides the active workflow file at `docs/process/workflows.xml`. Compass must use that project process workflow as the single active workflow source for design vocabulary, phase outputs, and evidence details.

Preset docs are reference material. When the selected preset contains examples from one language or stack, Compass must adapt the generated docs to the project's selected or detected language/framework before treating bootstrap as complete. The adaptation must preserve detail, rules, checklists, and evidence requirements while rewriting stack-specific folder names, file names, entrypoints, adapter names, and test conventions.

For `clean-solid-tdd`, Compass must review `docs/architecture/folder-file-structure.md`, `docs/architecture/clean-architecture.md`, `docs/process/tdd-workflow.md`, and `docs/process/workflows.xml` for stack-specific wording before reporting bootstrap complete.

## Presets

| Preset | Short description | When it fits |
| --- | --- | --- |
| `clean-solid-tdd` | Enterprise-grade Clean Architecture layering, explicit folder/file structure, SOLID, and TDD | Frontend, backend, full-stack, API, and business systems that need protected dependency direction, clear boundaries, and test-first discipline |
| `vertical-cupid-incremental` | Vertical Slice Architecture, explicit feature-slice structure, CUPID/YAGNI/KISS, and incremental tests | Small to medium products that benefit from feature-local change, low ceremony, and avoiding over-layering |
| `ddd-solid-bdd` | Domain-Driven Design, explicit bounded-context structure, domain modeling, SOLID, and BDD plus TDD | Complex business domains that need ubiquitous language, bounded contexts, aggregates, and executable behavior examples |
| `existing-architecture-lock` | Preserve and document the architecture, principles, and workflow already present in the project | Mature projects with a coherent existing structure that should be extended instead of replaced |
| `research-based` | Research current sources, compare options, cite evidence, then lock the selected direction | Unknown domains, unfamiliar teams, or explicit requests to research architecture alternatives |

## Selection Rules

- Offer the preset list before bootstrapping when the project has no orientation lock.
- Do not use `clean-solid-tdd` silently just because the user did not specify a preset.
- Use `vertical-cupid-incremental` when the user asks for feature-first delivery, low ceremony, or avoiding over-layering.
- Use `ddd-solid-bdd` when domain complexity, bounded context, ubiquitous language, aggregates, or business modeling is central.
- Use `existing-architecture-lock` without asking only when the project already has code, docs, or conventions that clearly should be preserved.
- Use `research-based` when the user asks Compass to search, compare, or choose from current external architecture references.

## Research-Based Preset Rule

The `research-based` preset is not a license to invent. Before locking it, Compass must search current sources, prefer primary or authoritative references, compare at least three viable architecture/principle/workflow combinations, then write the selected decision with source links and trade-offs.
