---
type: architecture
status: active
owner: architecture
created: 2026-09-15
updated: 2026-09-15
parent: "[[docs/architecture/README]]"
summary: Where each environment's declared state lives, how environments and state are separated, and how the toolchain maps onto that layout.
tags:
  - docs/architecture
  - status/active
aliases:
  - infrastructure layout
  - environment layout
  - declared state
related:
  - "[[docs/foundation/operations-principles]]"
  - "[[docs/process/change-workflow]]"
  - "[[docs/decisions/0001-orientation-lock]]"
---

# Infrastructure Layout

This document tells a reader where the declared state of each environment lives, what applies it, and what a change can reach.

## Core Rule

Each environment has its own declared state: its own inventory, state backend, workspace, or values. A change reaches only the environments it names. Shared building blocks are reused, but they are applied per environment.

## Layout Shape

Adapt this shape to the repository's toolchain during bootstrap:

```text
environments/   one inventory, state, or values set per environment
modules/        reusable units: modules, roles, charts, or bases
entrypoints/    what gets applied: root modules, playbooks, releases
policies/       optional policy-as-code checks
docs/
```

## Toolchain Mapping

Replace this table with the rows for the tools this repository actually uses, and remove the rest.

| Concept | Terraform | Ansible | Helm or Kubernetes |
| --- | --- | --- | --- |
| Environment boundary | Root module or workspace per environment, separate state backend | `inventories/<env>/` | Values file or overlay per environment, namespace or cluster |
| Reusable unit | Module | Role | Chart or base |
| Entry point | Root module | Playbook | Release or kustomization |
| Plan or dry-run | `terraform plan` | `ansible-playbook --check --diff` | `helm diff upgrade` or `kubectl diff` |
| Apply | `terraform apply` | `ansible-playbook` | `helm upgrade` or `kubectl apply` |
| Drift check | Scheduled plan | Check mode against the inventory | `kubectl diff` or GitOps sync status |

## State Ownership And Ordering

- Every piece of state has one owner. Split state by blast radius, for example network, platform, and workloads.
- When a change spans several states or environments, the change design states the apply order. Foundational state goes first.
- Never move or import state without a rollback plan for that step.

## Secrets

- No plaintext secrets in the repository. Reference a secret manager or an encrypted store.
- Every change records which secrets it reads or writes.

## What Does Not Belong Here

- Application source code.
- Step-by-step operational procedures; those are runbooks under the `docs/runbooks/` hub.
