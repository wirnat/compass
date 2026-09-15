---
type: decision
status: active
owner: architecture
created: 2026-09-15
updated: 2026-09-15
parent: "[[docs/decisions/README]]"
summary: Locks this repository to the infra-ops preset for declared-state infrastructure operations.
tags:
  - docs/decisions
  - status/active
aliases:
  - orientation lock
related:
  - "[[docs/architecture/infrastructure-layout]]"
  - "[[docs/foundation/operations-principles]]"
  - "[[docs/process/change-workflow]]"
---

# 0001 Orientation Lock

## Decision

Compass locks this project to the `infra-ops` preset.

## Stack

Record the toolchain this repository uses, such as Terraform, Ansible, Helm, Kubernetes manifests, or Pulumi, and the environments it manages. The preset docs use generic terms such as declared state, plan, dry-run, and apply; adapt them to the commands of this toolchain.

## Architecture

Use [[docs/architecture/infrastructure-layout]].

## Principles

Use [[docs/foundation/operations-principles]].

## Development Workflow

Use [[docs/process/change-workflow]]. Risk tiers and gates live in `docs/process/workflows.xml`.

## Consequences

- Every change to a live environment starts as a change to declared state in this repository.
- Every change gets exactly one risk tier, and the tier decides approval and rehearsal depth.
- Plan or dry-run evidence comes before apply; live verification comes after.
- Console or CLI changes outside the workflow are break-glass only and are recorded immediately.
