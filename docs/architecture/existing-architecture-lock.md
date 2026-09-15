---
type: architecture
status: active
owner: architecture
created: 2026-05-21
updated: 2026-09-15
parent: "[[docs/architecture/README]]"
tags:
  - docs/architecture
  - status/active
aliases:
  - existing architecture
related:
  - "[[docs/decisions/0001-orientation-lock]]"
---

# Existing Architecture Lock

This project preserves the architecture already present in the Compass skill
repository.

## Current Architecture

Compass is a reference-driven Codex skill package.

- `SKILL.md` is the skill entrypoint and workflow enforcement surface.
- `README.md` explains the product model and user-facing behavior.
- `references/*.xml` stores shared rules that the skill loads at runtime.
- `assets/docs-seed/` stores common project documentation seeds.
- `assets/orientation-presets/<preset>/docs/` stores preset-specific docs and workflows.
- `scripts/bootstrap-docs.sh` copies seed and preset docs into a target project.
- `scripts/docs-index.sh` prints an on-demand YAML index of a project's docs from note frontmatter.
- `scripts/skills-check.sh` reports which recommended skills are installed; `scripts/lib/yaml.sh` holds the shared YAML quoting.
- `agents/openai.yaml` stores OpenAI plugin metadata.
- `docs/` stores this repository's own Compass context.

There is no application runtime, package manager, or compiled artifact in the
current repository. The main executable behavior is the portable shell scripts
under `scripts/`.

## Protected Boundaries

- Skill policy belongs in `SKILL.md`.
- Shared task classification and workflow references belong in `references/`.
- Generic docs that every bootstrapped project receives belong in `assets/docs-seed/`.
- Preset-specific docs belong in `assets/orientation-presets/<preset>/docs/`.
- Bootstrap mechanics belong in `scripts/bootstrap-docs.sh`.
- Docs index generation belongs in `scripts/docs-index.sh`.
- Recommended skill checks belong in `scripts/skills-check.sh`, and shared script helpers belong in `scripts/lib/`.
- This repository ignores its own `docs/.tasks/` because `scripts/update-skill.sh` copies `docs/` into every installed skill; task memory here stays local.
- Repository context and decisions belong in `docs/`.
- Task memory artifacts for target projects belong under target project `docs/.tasks/`; task memory templates belong in `assets/docs-seed/_templates/`.

## Lock Rules

- Grow inside the existing structure.
- Do not create competing layer names or root folders without an architecture decision.
- Keep new code consistent with existing tests, package boundaries, and composition style.
- When the existing structure is unclear or contradictory, document the ambiguity before changing it.
- Do not create another active workflow source outside `docs/process/workflows.xml`.
- Do not duplicate Compass policy across multiple root markdown files.
- Keep script paths relative and portable; do not introduce user-specific absolute paths.
- Scripts target macOS bash 3.2 and POSIX awk: no associative arrays, globstar, or empty arrays under `set -u`, and no large here-strings, which crashed bash 3.2 on a real project. Do text processing in awk.

## Allowed Folder Growth

- Add new `references/*.xml` files only for reusable policy or taxonomy that is too large or too structured for `SKILL.md`.
- Add new `assets/docs-seed/` files only when every bootstrapped Compass project should receive them.
- Add new preset files under `assets/orientation-presets/<preset>/docs/` only when the behavior belongs to that preset.
- Add tests or fixtures under `tests/`, following `docs/process/testing-strategy.md`.
- Add docs under the existing `docs/` taxonomy.
- Add hidden `docs/.tasks/` folders inside target projects only for approved gated design context or long/risky multi-slice work after goal alignment.

## Disallowed Competing Patterns

- Runtime-specific app folders such as `src/`, `internal/`, `cmd/`, or `packages/` without an architecture decision.
- Multiple bootstrap scripts that perform overlapping docs seeding.
- A second workflow file treated as active source of truth.
- Generated or long-lived task context outside target project `docs/`.

## Verification Commands

- `./scripts/bootstrap-docs.sh --list-presets`
- `./scripts/bootstrap-docs.sh --target <project> --preset <preset> --dry-run`
- `./scripts/bootstrap-docs.sh --target <project> --preset <preset>`
- `./scripts/smoke-test.sh`
- `./tests/run-tests.sh`

No dedicated build or lint command exists yet.
