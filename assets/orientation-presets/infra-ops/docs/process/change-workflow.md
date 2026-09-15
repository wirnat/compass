---
type: process
status: active
owner: engineering
created: 2026-09-15
updated: 2026-09-15
parent: "[[docs/process/README]]"
summary: How an infrastructure change moves from idea to live environment, how to pick a risk tier, and what evidence each change leaves.
tags:
  - docs/process
  - status/active
aliases:
  - change workflow
  - change management
  - risk tier
  - rollback plan
  - break-glass
related:
  - "[[docs/architecture/infrastructure-layout]]"
  - "[[docs/foundation/operations-principles]]"
---

# Change Workflow

This guide shows how to apply the infra-ops gates in practice. The risk tier definitions and phase gates live in `docs/process/workflows.xml`, under `<risk-tiering>` and the `infra_change` workflow. This guide does not redefine them.

## Flow

```text
change-discovery -> change-design -> declared-state-implementation -> live-rollout
```

Discovery and design need developer approval. Implementation edits declared state only and stops before any command that contacts a live environment. Live-rollout runs the plan or dry-run, gets approval as the tier requires, applies, verifies, and records.

## Choosing A Tier

Pick the tier from what the change can break, not from how many lines it touches. When in doubt, pick the higher tier. A plan that shows a destroy or replace raises the tier to at least C, whatever was assigned earlier.

Examples:

- Tier A: add a tag, reformat, change a comment or an unused default.
- Tier B: change a configuration value or variable contract that reverts cleanly.
- Tier C: restart or reconfigure a service, change a firewall rule, scale a workload.
- Tier D: delete data, destroy or replace a resource, reboot a stateful node, rotate a secret that cannot be restored.

## Reading A Plan Or Dry-Run

1. Read the summary line first. Any destroy or replace changes how the rest is read.
2. Look for resources or hosts outside the intended scope. If any appear, stop.
3. Call out changes to secrets, access control, and network exposure.

## Rollback Plan Format

Tier A and Tier B, one line:

```text
revert: <how the change is undone>
```

Tier C, three fields:

```text
revert_via: <command, commit revert, or previous version>
verify: <how to confirm the rollback worked>
time_estimate: <how long the rollback takes>
```

Tier D adds a pre-apply artifact, such as a backup or snapshot reference, and a written runbook for the apply.

## After Applying

Verify the live result with the checks from the change design, then record what changed, who approved it, and how it was verified. Update runbooks when operations changed.

## Break-Glass

During an incident, console or CLI changes may restore service. Approval before each mutating command still applies. Record what changed, when, by whom, and why, while it is fresh. Then open an `infra_change` to bring declared state in line or to revert the live change.

## Drift

Record drift before reconciling it. Then decide whether to adopt the live state into declared state or to revert the live change, and record why.

## Evidence

The project decides where evidence lives, for example a merge request or task memory. The minimum for each change: risk tier, rollback plan, plan or dry-run summary, approvals, and live verification.
