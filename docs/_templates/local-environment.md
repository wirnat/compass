---
type: process
status: draft
owner: engineering
created: "{{date:YYYY-MM-DD}}"
updated: "{{date:YYYY-MM-DD}}"
parent: "[[docs/process/README]]"
summary: How to run this project and its tests locally without duplicating services other projects already run.
tags:
  - docs/process
  - status/draft
aliases:
  - local environment
  - run locally
related:
  - "[[docs/foundation/testing-principles]]"
---

# Local Environment

<!-- Sample template. Keep the sections that fit this project and adapt the examples to its stack. -->

## Run The App

{{run_command}}

## Shared Services

Services this project uses from the team's shared dev infrastructure. Reuse them instead of starting another copy.

| Service | Source | How to start | How to reach it |
| --- | --- | --- | --- |
| {{service}} | {{shared_infra_repo_or_owner}} | {{start_command_or_profile}} | {{host_port_or_network}} |

## Project-Owned Services

Services this project must run itself, and why the shared one is not enough, such as a different version, extension, or data shape.

| Service | Reason | How to start |
| --- | --- | --- |
| {{service}} | {{reason}} | {{start_command_or_profile}} |

## Tests

- Static checks: {{format_lint_and_type_check_command}}
- Unit: {{unit_test_command}}
- Integration: {{integration_test_command}}. Data isolation: {{database_schema_or_prefix_per_run}}
- End-to-end: {{e2e_test_command}}. Starts: {{services_needed}}

## Ports And Environment Keys

List key names only, never values.

| Key or port | Purpose |
| --- | --- |
| {{key_or_port}} | {{purpose}} |

## Hot Reload And Dependency Caches

Rebuild incrementally, reuse dependency caches, and do not rebuild images on every change. Adapt the examples to this stack:

- A compiled service can run a file watcher, such as air for Go, with module and build caches shared across projects.
- A JavaScript project can pin a package manager with a shared store, such as pnpm set in the `packageManager` field.

{{hot_reload_setup}}

## Cleanup

How to stop and remove what this project started, without touching shared services.

{{cleanup_command}}
