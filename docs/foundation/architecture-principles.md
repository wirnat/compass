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
  - architecture principles
  - clean architecture
  - SOLID
related:
  - "[[docs/foundation/engineering-philosophy]]"
  - "[[docs/process/implementation-workflow]]"
---

# Architecture Principles

This document defines the durable boundary rules for the project. The goal is not to make the code look academic, but to keep the most important behavior clear, testable, and protected from fast-changing technical details.

## Summary

Architecture is a rule about dependency direction and responsibility boundaries.

Source code dependencies should point toward stable policy and core behavior. Delivery mechanisms, databases, frameworks, queues, CLIs, files, and external services should live near the edge.

## Core And Edges

### Core Behavior

Core behavior contains the most stable rules:

- entities, values, and policies
- invariants and business decisions
- domain or product rules
- operations testable without delivery, persistence, framework, or external service dependencies

Core behavior should not import transport, persistence, runtime configuration, framework request objects, or external API payloads.

### Application Orchestration

Application orchestration coordinates a user or system goal:

- scenario validation
- branching
- conceptual transactions
- calls to ports or outside capabilities through small contracts
- mapping input to core behavior and output back to the caller

Contracts for outside capabilities should be owned by the consumer that needs them.

### Adapters

Adapters translate outside formats into shapes that are comfortable for the core, and back again:

- HTTP, CLI, UI, or worker inputs
- database rows or documents
- queue messages
- external API payloads
- file or storage formats

Adapters may contain technical details as long as those details do not leak inward.

### Platform

Platform code provides shared technical tools, not business behavior:

- configuration
- logging
- clocks
- identifiers
- connection setup
- runtime integration

## Practical Boundary Rules

1. If code contains stable business or product rules, keep it in the core.
2. If code coordinates an application goal, keep it in application orchestration.
3. If code translates outside formats, keep it in an adapter.
4. If code prepares shared technical tools, keep it in platform or infrastructure.
5. If an inner area needs an outer capability, define a small contract on the consumer side.
6. If data crosses a boundary, use a shape owned by the receiving boundary.
7. If a package starts to get a generic name, find clearer ownership.
8. If a test needs heavy infrastructure to prove a pure rule, inspect the boundary.

## SOLID As A Design Compass

Use SOLID as design language, not a ritual checklist:

- Single Responsibility: each unit has one primary reason to change.
- Open/Closed: stable behavior can grow without frequent rewrites.
- Liskov Substitution: implementations preserve consumer expectations.
- Interface Segregation: consumers depend only on methods they use.
- Dependency Inversion: stable policy depends on contracts, not concrete details.

## Review Checklist

- Do dependencies still point toward stable policy?
- Is core behavior free from framework, persistence, and transport details?
- Are contracts narrow and owned by their consumers?
- Do adapters translate instead of owning business rules?
- Is each interface created because a consumer needs it?
- Is each test at the cheapest level that still proves behavior?
- Is documentation updated when a boundary or principle changes?
