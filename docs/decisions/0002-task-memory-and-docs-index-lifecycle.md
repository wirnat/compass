---
type: decision
status: active
owner: architecture
created: 2026-09-15
updated: 2026-09-15
parent: "[[docs/decisions/README]]"
summary: Decisions and rejected options behind the docs index, task memory lint, infra_change, local runtime policy, supporting files, task close-out, and recommended skills.
tags:
  - docs/decisions
  - status/active
decision_id: "0002"
aliases:
  - task memory lifecycle
  - docs index decision
related:
  - "[[docs/decisions/0001-orientation-lock]]"
  - "[[docs/architecture/existing-architecture-lock]]"
---

# 0002 - Task Memory And Docs Index Lifecycle

## Status

Active. Decided with the developer on 2026-09-15.

## Context

Compass loaded project docs by reading category READMEs and opening notes one by one, and task memory under `docs/.tasks` grew without limits. A survey of the developer's Compass projects on 2026-09-15 found:

- task `goal.md` files up to 700 lines;
- 107 closed goals still in the repositories, almost all committed;
- 62 permanent docs linking into `docs/.tasks`;
- 19 of 29 task supporting files not linked from their goal;
- 191 compose files, 96 of them starting their own Postgres.

Several decisions followed. Each one lists the options that were rejected, so they do not come back without new evidence.

## Decisions

| Decision | Chosen | Rejected, and why |
| --- | --- | --- |
| Docs index | Generated on demand from frontmatter by `scripts/docs-index.sh` | A committed `docs/_index.yaml` or a hand-written manifest: a second source of truth that goes stale, conflicts on merge, and dirties the worktree when rebuilt |
| Task manifest | None; `goal.md` is the manifest, read with a fixed resume order | `task_manifest.yaml`: a third copy of slice status next to `goal.md` and `diagram.md` |
| Required headings | A small Compass core in `references/task-memory.xml`, matched case-insensitively | Enforcing project template headings: optional sections and evolving templates produced false warnings in real projects, so project headings only end the SUMMARIES region |
| Risk tiers | Owned by the project or the `infra-ops` preset; the core only has the Live Environment Gate | Tiers in the core: real projects use different tier counts (A-C and A-D) |
| Tooling language | Bash and POSIX awk | Python: an extra runtime, and its standard library has no YAML parser anyway |
| Local environment doc | A sample template, created when a task first needs to run the app or its tests | A required seed doc: every existing project would be offered bootstrap again |
| Supporting files | Allowed with no line limit when `goal.md` links them; durable ones move to permanent docs at close-out | Raising the `goal.md` limits: resume cost grows with every task |
| Task memory tracking | Committed by default; ignored only with a recorded reason | Ignored by default: loses team review and resume on another machine |
| Closed goals | Close-out: harvest into permanent docs, remove links into the task, delete the folder | Keeping closed goals as history: git history already keeps them, and live folders turn into stale sources of truth |
| Recommended skills | A manifest, an offline check, and install commands that run only with developer approval | Automatic install: third-party skills are instructions an agent follows, so an unreviewed change is a supply-chain risk. Vendored copies in the Compass repository: duplication, licensing, and stale copies. Version pins: the skills CLI lock already records hashes, and every install needs approval |

## Consequences

- The rules live in `SKILL.md`, `references/*.xml`, preset docs, and templates. `scripts/docs-index.sh` checks what can be checked deterministically.
- Judgement calls, such as whether a harvest is complete or an active goal is stale, stay with the agent and the developer.
- Reopening a rejected option needs new evidence and a new decision record that supersedes this one.
