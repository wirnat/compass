# Compass

AI coding agents can produce code quickly. Compass exists to make sure that code is worth maintaining.

Compass is an engineering discipline layer for agentic development. It forces a project to lock its architecture, philosophy, principles, and development workflow before implementation begins, then makes the agent work inside those boundaries. The goal is simple: code that stays clear, testable, and maintainable as the project grows.

Without Compass, an agent can write code that passes today and becomes painful next month. With Compass, the agent has to ask the questions senior engineers usually ask: Is this small enough? Will this still make sense in six months? Can a junior developer follow the flow? Are the tests proving behavior? Did we protect the architecture, or just hope nobody notices?

Compass turns a request like:

```text
Build a transaction feature.
```

into engineering work with a clear path:

```text
Which architecture preset is locked?
Which engineering philosophy applies?
Which principles are non-negotiable?
Is this a new_feature, bug_fix, refactor, or architecture_change?
Where does the active workflow come from?
Which project docs must be read?
Which behavior is approved?
Is task memory required before implementation?
What tests or evidence prove completion?
What is the first safe implementation slice?
```

## Why Compass

Most codebases do not decay because of one dramatic mistake. They decay through many small decisions that looked harmless at the time: a helper with no real owner, a test that proves implementation details, a shortcut around a boundary, a file that quietly grows until nobody wants to touch it.

Compass prevents that drift by turning development philosophy into enforceable workflow. It does not merely suggest "write better code." It makes the agent operate through locked orientation, documented principles, task-specific workflows, approval gates, and completion evidence.

| Without Compass | With Compass |
| --- | --- |
| Implements directly from a raw prompt | Classifies the task by risk first |
| Architecture shifts silently inside code | Architecture is locked before implementation |
| "Best practice" is left to the agent's mood | Philosophy and principles are written into project docs |
| Every request feels like a generic feature build | Bugs, refactors, incidents, migrations, security work, and releases use different workflows |
| Project docs are ignored unless linked from `AGENTS.md` | `docs/` becomes the automatic project context pack |
| Workflow source is unclear | Active workflow comes only from `docs/process/workflows.xml` |
| Large features are built in one pass | Feature work goes through brainstorming, design, then one implementation slice |
| Long work loses context between sessions | Multi-slice work gets a durable `docs/.tasks/` memory before implementation |
| Completion is claimed by confidence | Completion requires evidence: tests, checks, docs, or a clear reason |

Compass makes agents behave more like disciplined engineering partners. They still move quickly, but their speed is constrained by quality rules the project has already chosen.

## What Compass Provides

Compass gives a project the enforcement points needed to produce higher-quality code:

- **Orientation lock**: the project chooses architecture, principles, and development mechanism before implementation.
- **Engineering philosophy**: daily decisions are guided by maintainability, small scope, readable flow, useful comments, and behavior-focused tests.
- **Ready-to-use presets**: Clean Architecture, Vertical Slice, DDD, existing architecture, or research-based orientation.
- **Project-owned workflow**: the active workflow lives in one place, `docs/process/workflows.xml`.
- **Task Memory Gate**: approved gated design context or long/risky multi-slice work must create or resume a durable `docs/.tasks/` goal, diagram, and memory artifact before implementation starts.
- **Cross-IDE memory sync**: project knowledge persists across sessions and tools in `docs/.memory/`, split into shared (team, committed) and local (machine-specific, gitignored).
- **Evidence-driven execution**: each task type defines the proof needed before work can be called complete.

The result: the agent knows what quality means in this project before it writes code.

## The Philosophy Compass Enforces

The default engineering philosophy is intentionally practical:

- **Keep it small**: files, functions, packages, and scopes should stay as small as they can be while remaining clear.
- **Think six months ahead**: every technical decision should ask whether it will make maintenance harder later.
- **Write junior-readable code**: names, flow, and ownership should be understandable without heroic context.
- **Use comments for reasons**: comments explain why, assumptions, business rules, edge cases, and non-obvious decisions, not mechanical code.
- **Test behavior, not trivia**: tests should protect expected behavior at the cheapest meaningful level.
- **Avoid speculative abstraction**: abstractions need a real caller and a real reason to exist.

Compass turns these from nice advice into daily working constraints. It keeps small decisions healthy so the codebase does not slowly turn into a storage room where every box is labeled "misc".

## Orientation Presets

On first run, if a project does not yet have orientation docs, Compass does not silently choose a default. It offers prepared presets and waits for the developer to choose.

| Preset | What It Locks | Best For |
| --- | --- | --- |
| `clean-solid-tdd` | Clean Architecture, explicit folder/file structure, SOLID, TDD | Frontend, backend, full-stack, API, and business systems that need strong boundaries, clear dependency direction, and test-first discipline |
| `vertical-cupid-incremental` | Vertical Slice Architecture, feature-slice structure, CUPID, YAGNI, KISS, incremental tests | Small to medium products that benefit from feature-local change, lower ceremony, and avoiding over-layering |
| `ddd-solid-bdd` | Domain-Driven Design, bounded contexts, domain modeling, SOLID, BDD plus TDD | Complex business domains that need ubiquitous language, aggregates, bounded contexts, and executable behavior examples |
| `existing-architecture-lock` | The architecture, principles, and workflow already present in the project | Mature projects with coherent conventions that should be extended, not replaced |
| `research-based` | A researched architecture, principle set, and workflow selected from current sources | Unknown domains, uncertain teams, or projects where the developer wants Compass to research alternatives |
| `infra-ops` | Declared-state infrastructure layout, operations principles, A-D risk tiers, and a gated `infra_change` workflow | Infrastructure, platform, and operations repositories: IaC, configuration management, cluster manifests, and server fleets |

Presets are not just folder templates. They seed `docs/` with decisions, principles, structure, and workflows that become the agent's operating context.

## How It Works

Compass follows this flow:

1. On the first Compass-guided task in a Codex session, check the installed Compass skill against `https://github.com/wirnat/compass` and update it before continuing when the installed copy is stale.
2. Check whether the project already has orientation docs under `docs/`.
3. If not, offer orientation presets and bootstrap only after the developer chooses.
4. Seed project docs, including `docs/decisions/0001-orientation-lock.md`.
5. Copy the selected preset workflow to `docs/process/workflows.xml`.
6. Create or update a `<!-- compass:start -->...<!-- compass:end -->` block in agent gateway files (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `COPILOT.md`, `.claude/rules/`, `.cursor/rules/`) so any agent starting a new session knows this project uses Compass. Auto-detects existing files; falls back to `AGENTS.md`.
7. Read relevant project docs: orientation lock, architecture, foundation, process, module docs, and decisions.
8. Classify the task by engineering risk, not by wording alone.
9. Run the active workflow from `docs/process/workflows.xml`.
10. Before implementation, run the Task Memory Gate: for approved gated design context or long/risky multi-slice work, inspect or create `docs/.tasks/<task>/` after goal alignment and report `created`, `resumed`, or `not-required`.
11. Allow implementation only through the workflow's gates and required evidence.

Important rule: **Compass does not use a root-skill workflow fallback.** If a project does not have `docs/process/workflows.xml`, Compass must seed or migrate the project docs first. One active workflow source. Two compasses on one desk is how people start arguing with furniture.

## Quick Start

List available presets:

```bash
./scripts/bootstrap-docs.sh --list-presets
```

Bootstrap a project with a preset:

```bash
./scripts/bootstrap-docs.sh --target /path/to/project --preset clean-solid-tdd
```

Preview changes without writing files:

```bash
./scripts/bootstrap-docs.sh --target /path/to/project --preset clean-solid-tdd --dry-run
```

Overwrite existing docs only when that is intentional:

```bash
./scripts/bootstrap-docs.sh --target /path/to/project --preset clean-solid-tdd --force
```

When Compass is installed through the `skills` CLI, prefer the CLI-managed update path:

```bash
npx skills update
```

For git-backed, manual, or non-CLI installations, resolve the fallback scripts relative to the loaded skill directory:

```bash
/path/to/installed/compass/scripts/update-skill.sh --skill-dir /path/to/installed/compass
/path/to/installed/compass/scripts/bootstrap-docs.sh --list-presets
/path/to/installed/compass/scripts/bootstrap-docs.sh --target . --preset clean-solid-tdd
```

The update check uses the GitHub repository as the source of truth. If the
installed skill is stale or has no recorded source revision, the selected updater
refreshes the skill directory first, then the agent must reload `SKILL.md`
before continuing. Once a newer map exists, do not keep walking with a photocopy
of the old one.

## Testing

Run the deterministic test suite before completing changes to Compass policy,
presets, workflows, scripts, or tests:

```bash
./tests/run-tests.sh
```

The wrapper checks shell syntax, XML validity, bootstrap smoke behavior, docs
links, workflow coverage, policy consistency, update-skill fallback behavior,
all preset bootstrap outputs, docs index output, and the recommended skills
check. Slow headless agent tests are not part of the default suite.

## Routing Output Example

Compass does not just say "I will work on it." It states the task type, workflow source, and evidence needed:

```xml
<task-routing>
  <primary-type>bug_fix</primary-type>
  <secondary-type>none</secondary-type>
  <why>The request restores expected behavior after a defect.</why>
  <workflow-source>docs/process/workflows.xml</workflow-source>
  <workflow>
    <step>Reproduce or gather evidence for the bug.</step>
    <step>Minimize the failing scenario.</step>
    <step>Identify root cause before editing.</step>
    <step>Add a failing regression test.</step>
    <step>Fix the smallest cause.</step>
    <step>Run targeted tests, then broader tests if risk warrants.</step>
  </workflow>
  <evidence>Reproduction, regression test, and passing verification.</evidence>
  <commit-hint>fix</commit-hint>
</task-routing>
```

## New Feature Workflow

For `new_feature`, Compass is intentionally strict:

1. **Brainstorming**: understand the problem, users, success criteria, scope, and non-goals.
2. **Design**: define the contract, domain shape, behavior-test matrix, and behavior decisions.
3. **Task Memory Gate**: before implementation, create or resume `docs/.tasks/<task>/` for approved gated design context or long/risky multi-slice work, or state why it is not required.
4. **Implementation**: build one small slice, verify it, then stop for validation.

A request to "build feature X" is not permission to skip brainstorming and design. It is the starting bell, not the finish line.

## Feature Update Workflow

For `feature_update`, Compass protects the existing behavior before changing it.
An update is not a smaller new feature; it is a controlled delta from a known
baseline.

1. **Baseline discovery**: find the owner, current behavior, tests, contracts, docs, commands, and behavior that must not drift.
2. **Delta design**: define old behavior, new behavior, unchanged behavior, regression tests, slices, docs impact, and rollout risk.
3. **Task Memory Gate**: before implementation, create or resume task memory for approved delta design context or long/risky multi-slice updates, or state why it is not required.
4. **Implementation checkpoints**: build one approved delta slice, verify preserved and changed behavior, then stop for validation.
5. **Rollout cleanup**: close feature flags, dark-launch paths, compatibility paths, docs, runbooks, or rollback notes introduced by the update.

Minor updates can pass through this quickly. Medium and high-risk updates should
not skip baseline and delta approval, because changing old behavior without
knowing what must stay still is how software becomes a cupboard full of cables:
everything is connected, nobody knows why.

## Live Environment Gate

Compass treats a change to a running environment differently from a change to
code. Work that changes a live environment, or the declared infrastructure state
applied to one, is classified as `infra_change`, either as the primary type or
as a secondary type next to a feature, fix, release, or incident.

Before any command that mutates a live environment (apply, deploy, restart,
delete, scale, a secret write, or a console change), Compass shows plan or
dry-run evidence for that exact change, states the rollback plan, and asks for
explicit approval of that command. After the change it verifies the live result
instead of re-reading command output, and records what changed. During an
incident the phases may be shortened, but approval before each mutating command
still holds, and break-glass changes are recorded right after.

Risk tiers, approval depth, and tool-specific commands belong to the project's
workflow or preset. The Live Environment Gate is only the minimum Compass
enforces everywhere. Infrastructure repositories can choose the `infra-ops`
preset, which ships A-D risk tiers and a full `infra_change` workflow. Projects
on other presets can copy that workflow into their own `docs/process/workflows.xml`.

## Local Runtime Policy

A developer machine runs many projects, and it is easy to start the same
database, cache, or observability stack once per project without noticing.
When Compass runs the application or its tests locally, it reads the project's
`docs/process/local-environment.md`, checks what is already running, reuses
shared services, starts only what the task needs, and stops what it started
when the task ends. It never stops or removes containers, volumes, images, or
networks it did not start without approval, and never points local runs at
remote databases.

`docs/_templates/local-environment.md` is a sample: each project records which
services come from the team's shared dev infrastructure, which it owns and why,
its test commands, and how to clean up. Stack-specific advice, such as a file
watcher for compiled services or a package manager with a shared store, is
adapted to the project during bootstrap.

## Static Checks And Code Intelligence

Static checks are required evidence: every project records its formatter,
linter, and type check commands, runs them with the tests for each slice, and
reports a missing setup as a gap instead of adding tooling silently. Compass does
not pick the tools; it adapts to the stack.

Code Intelligence tools, such as GitNexus or other code graphs, are recommended,
not required. When a project uses one, the agent checks that the index matches
`HEAD` before trusting it, uses it for impact analysis before refactors and
architecture changes, and confirms its answers in the code.

## Recommended Skills

`references/recommended-skills.xml` lists optional skills that strengthen
Compass phases, such as brainstorming, plan writing, test-driven development,
systematic debugging, and verification. Projects can add their own in
`docs/process/recommended-skills.xml`. After the Session Update Gate,
`scripts/skills-check.sh` reports which ones are installed, without network
access, and prints `npx skills add` commands for the missing ones. Compass runs
an install command only with developer approval: skills are instructions an
agent follows, so each one is reviewed before it lands. Compass works without
any of them.

## Task Memory Gate

Task memory exists so a long task can survive context loss, session changes, and the natural erosion of attention. Goal is the vision; slices are the missions. Missions may change while the goal remains stable. If the goal changes, Compass treats it as a new goal and supersedes the old task memory.

Compass must run the Task Memory Gate before implementation starts. The gate has three allowed outcomes:

| Outcome | Meaning |
| --- | --- |
| `created` | A new task memory folder was created for the aligned goal. |
| `resumed` | One active relevant task memory folder was loaded and reused. |
| `not-required` | The task is small, single-slice, or below the memory threshold. The agent must state why. |

Task memory is required when either condition is true:

1. A Compass workflow has developer-approved gated design context to preserve before implementation, such as brainstorming, align-context, evidence-discovery, fit-design, design, baseline-discovery, or delta-design, even when the approved implementation has one slice.
2. The task is long or risky, such as `new_feature`, `architecture_change`, a large refactor, or work with meaningful checkpoint risk, and there are at least two concrete implementation slices after alignment or design.

If neither condition applies, Compass reports `not-required` with the reason before implementation starts.

When required, Compass creates this structure in the target project before the first implementation edit or command:

```text
docs/.tasks/
`-- <YYYYMMDD-HHMM>_<goal_slug>/
    |-- goal.md
    |-- diagram.md
    `-- memories.md
```

The files have different jobs:

- `goal.md`: goal name, status, description, non-goals, optional Do and Don't guardrails, success criteria, slice list, evidence, and links to superseded or successor goals. A Don't records an approach the developer rejected, with its reason, so a later session does not take that shortcut again.
- `diagram.md`: Mermaid checkpoint diagram plus text fallback. Pending slices are gray, active is blue, done is green, blocked is red.
- `memories.md`: `SUMMARIES` plus newest-first `HISTORIES`, including user intent, agent rationale snapshot, and agreement. It must not expose private chain-of-thought.

When resuming, Compass reads `goal.md` in full and only the `SUMMARIES` section plus the newest `HISTORIES` entry of `memories.md`. `diagram.md` is for humans. Resume stays cheap as histories grow, and no separate manifest file is needed because `goal.md` already holds the goal status and slice list.

Compass finds open goals with `scripts/docs-index.sh --tasks`, which lists `docs/.tasks/` goals from `goal.md` frontmatter and warns about missing files, invalid `goal_status`, bad folder names, missing Compass-required headings, `goal.md` over 120 lines, or summaries over 60 lines. Task templates belong to each project and the Compass templates are samples: a project may change its sections freely as long as it keeps the headings listed under `required-headings` in `references/task-memory.xml`. To keep resume cheap, `goal.md` holds current state with one Latest Evidence entry replaced at each slice, per-slice evidence goes into `HISTORIES`, and `SUMMARIES` is rewritten at each checkpoint. Active goals untouched for more than 14 days are offered for closing before a goal is selected.

Longer material, such as API contracts, schemas, fixtures, or detailed notes, can live in supporting files inside the task folder with no line limit. `goal.md` lists each supporting file under References with when to read it, `docs-index.sh --tasks` warns about files nobody links, and files that remain the source of truth after the task move to the project's durable location when the goal completes.

Closed goals do not stay: their close-out harvests each goal's durable knowledge into modules, decisions, reference, runbooks, or process docs with approval, removes every link from permanent docs into the task folder, records the summary in the commit or merge request, and then deletes the folder with approval. Knowledge flows from task memory into docs, never the other way. Task memory is committed by default so the team can review and resume it; a project that ignores `docs/.tasks` records why, and `docs-index.sh --tasks` reports which mode is in use and flags folders that break it.

At every slice boundary, Compass updates task memory before reporting the checkpoint. If a slice starts, completes, blocks, or changes, update the same folder. If the goal changes, create a new task folder, mark the old goal `superseded`, cross-link both folders, and record the reason in both `memories.md` files.

Missing task memory templates in the target project do not waive the gate. Compass must use the installed templates or `references/task-memory.xml`, then report the documentation gap.

## Cross-IDE Memory Sync

Compass maintains project knowledge across sessions and tools in `docs/.memory/`. The memory layer splits into two areas:

- `docs/.memory/shared/`: team knowledge committed to version control
- `docs/.memory/local/`: machine-specific knowledge gitignored per developer

When developers use different IDEs or agents (Claude Code, Qoder, Cursor, etc.), each tool may accumulate its own project memories. `scripts/memory-sync.sh` detects these provider-specific memories, classifies each as shared or local using keyword-based rules from `references/memory-providers.xml`, and imports them into the Compass memory structure.

Import memories from a specific provider:

```bash
./scripts/memory-sync.sh --target /path/to/project --provider claude-code
```

Auto-detect all providers:

```bash
./scripts/memory-sync.sh --target /path/to/project
```

Preview without writing:

```bash
./scripts/memory-sync.sh --target /path/to/project --dry-run
```

The bootstrap script creates the `docs/.memory/` structure automatically and adds `docs/.memory/local/` to `.gitignore`.

### Memory Lifecycle

Memories include lifecycle fields in their frontmatter:

- `status`: `active`, `stale`, `archived`, or `deprecated`
- `expires`: ISO-8601 expiration date (empty = no expiration)
- `related`: list of related memory or doc paths

Use `memory-index.sh --lifecycle` to report on memory health:

```bash
./scripts/memory-index.sh --target /path/to/project --lifecycle
```

This reports each memory's lifecycle state: active, stale (>90 days old), expired (past expiration date), or archived/deprecated.

### Audit Trail

Use `--verbose` with `memory-sync.sh` for detailed classification and import logging:

```bash
./scripts/memory-sync.sh --target /path/to/project --verbose
```

Operations are logged to `docs/.memory/sync-log.json` with timestamp, provider, source, classification, destination, and outcome for each memory processed.

## Custom Workflows

Projects can extend preset workflows with custom task types. Create `docs/process/custom-workflows.xml` (seeded during bootstrap) and add your workflow definitions:

```xml
<custom-workflows>
  <workflow type="data_pipeline">
    <description>Add or modify a data pipeline stage.</description>
    <steps>
      <step order="1">Identify data sources and sinks.</step>
      <step order="2">Add schema validation.</step>
      <step order="3">Implement pipeline stage.</step>
    </steps>
    <evidence>Schema validation and integration tests.</evidence>
  </workflow>
</custom-workflows>
```

Validate and merge with preset workflows:

```bash
# Validate custom workflows
./scripts/resolve-workflows.sh --target /path/to/project --validate

# Merge into resolved file
./scripts/resolve-workflows.sh --target /path/to/project --output docs/process/resolved-workflows.xml
```

Custom workflow types must not conflict with preset types. The validator checks for duplicates, missing elements, and structural issues.

## CI/CD Integration

Use `scripts/ci-check.sh` in CI pipelines to enforce Compass docs quality:

```bash
# GitHub Actions
- run: ./scripts/ci-check.sh --target .

# GitLab CI
script:
  - ./scripts/ci-check.sh --target . --strict
```

The CI check runs 5 validations:
1. Bootstrap validation (required files, XML, orientation lock, gateways)
2. Custom workflow validation (structure, conflicts)
3. Docs index freshness (index matches current docs)
4. Link integrity (internal doc links valid)
5. Policy consistency (classification and documentation rules)

Use `--strict` to treat warnings as failures, `--quiet` for minimal output.

## CI/CD Pipeline

Compass includes GitHub Actions workflows for continuous integration and automated releases:

### CI Workflow (`.github/workflows/ci.yml`)

Runs automatically on every push to `main` and on pull requests:

- Executes the full test suite (`./tests/run-tests.sh`)
- Runs CI checks in strict mode (`./scripts/ci-check.sh --strict`)

### Release Workflow (`.github/workflows/release.yml`)

Fully automatic releases using [semantic-release](https://semantic-release.gitbook.io/) based on [Conventional Commits](https://www.conventionalcommits.org/):

| Commit Prefix | Version Bump |
|---------------|-------------|
| `fix:` | patch (1.0.0 → 1.0.1) |
| `feat:` | minor (1.0.0 → 1.1.0) |
| `feat!:` or `BREAKING CHANGE:` | major (1.0.0 → 2.0.0) |

When you push to `main` with a `feat:` or `fix:` commit, semantic-release automatically:

1. Analyzes commit messages to determine the version bump
2. Generates release notes
3. Updates `CHANGELOG.md`
4. Updates the `VERSION` file
5. Commits changes with `chore(release): vX.Y.Z`
6. Creates and pushes a git tag
7. Creates a GitHub Release

Other commit types (`docs:`, `refactor:`, `chore:`, etc.) do not trigger a release.

Configuration is in `.releaserc.json`.

### Version Management

Versions are managed automatically by the release workflow. For manual control, use `scripts/version.sh`:

```bash
# Show current version
./scripts/version.sh

# Bump version manually (major, minor, or patch)
./scripts/version.sh bump patch

# Create git tag for current version
./scripts/version.sh tag
```

The automatic release workflow handles version bumps based on commit messages, so manual version management is only needed for special cases.

## Automatic Docs Context

Compass treats `docs/` as the project's context pack.

Compass also creates and maintains a `<!-- compass:start -->...<!-- compass:end -->` block in agent gateway files during bootstrap. The script auto-detects existing files: `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `COPILOT.md`, `.claude/rules/`, and `.cursor/rules/`. It writes the Compass block to every gateway file it finds, falling back to `AGENTS.md` when none exist. This block acts as a persistent reminder for any agent starting a new session that the project uses Compass workflow enforcement. The block includes Always Do rules, Never Do rules, and a Key Docs table. The LLM adapts the block to the project context after bootstrap, adding project-specific rules as needed.

Key docs used by Compass:

- `docs/decisions/0001-orientation-lock.md`
- `docs/process/workflows.xml`
- `docs/architecture/*`
- `docs/foundation/*`
- `docs/process/*`
- `docs/modules/*`
- `docs/decisions/*`
- `docs/reference/*`

Compass does not load all of these. After the orientation lock and `docs/process/workflows.xml`, it runs `scripts/docs-index.sh`, which prints a YAML index built from each note's frontmatter: path, type, status, `summary`, `aliases`, `related`, and `code` globs. The agent loads only the notes whose summary or aliases match the task, or whose `code` globs match files it will touch. The index is generated on every run and never stored, so it cannot drift from the notes. Adding `summary` and `code` to frontmatter makes the selection sharper; see `docs/reference/note-schema.md`.

If code and docs disagree, Compass should stop before broad changes and call out the conflict. Quietly choosing a side is how architecture turns into folklore.

Documentation language: Compass files, project docs, and task memory are written in English by default so every coding agent can follow them. A project can lock another language in its orientation lock; domain terms stay in their original language, and chat follows the developer's preference.

## Task Types

Compass uses an engineering task taxonomy so every request is not treated as the same kind of work:

| Type | When To Use |
| --- | --- |
| `new_feature` | Add a new capability or use case, even inside an existing module |
| `feature_update` | Change behavior of an already-existing use case or flow |
| `bug_fix` | Fix a defect |
| `hotfix_incident` | Restore urgent or production-impacting behavior |
| `refactor` | Change structure without changing behavior |
| `architecture_change` | Change boundaries, dependency direction, or architecture pattern |
| `db_migration` | Change schema, data ownership, migrations, or persistence assumptions |
| `infra_change` | Change a live environment or the infrastructure state applied to it |
| `performance` | Improve performance using baseline and evidence |
| `security` | Close a vulnerability or sensitive-data risk |
| `dependency_update` | Update dependencies and compatibility expectations |
| `build_ci_tooling` | Change build, CI, scripts, or developer tooling |
| `docs_only` | Change documentation without code behavior changes |
| `test_only` | Add or adjust tests without production behavior changes |
| `cleanup_chore` | Make small low-risk cleanup changes |
| `research_spike` | Investigate before deciding |
| `release_deploy` | Prepare release or deployment work |

## Repository Structure

```text
.
|-- SKILL.md
|-- VERSION
|-- CHANGELOG.md
|-- agents/
|   `-- openai.yaml
|-- assets/
|   |-- docs-seed/
|   |   `-- _templates/
|   |       |-- task-diagram.md
|   |       |-- task-goal.md
|   |       `-- task-memories.md
|   `-- orientation-presets/
|       `-- <preset>/
|           `-- docs/
|               `-- process/
|                   `-- workflows.xml
|-- references/
|   |-- bootstrap-rules.xml
|   |-- classification.xml
|   |-- documentation-policy.xml
|   |-- memory-providers.xml
|   |-- task-memory.xml
|   `-- task-types.xml
|-- scripts/
|   |-- bootstrap-docs.sh
|   |-- docs-index.sh
|   |-- lib/
|   |   `-- yaml.sh
|   |-- memory-sync.sh
|   |-- memory-index.sh
|   |-- resolve-workflows.sh
|   |-- ci-check.sh
|   |-- version.sh
|   `-- skills-check.sh
|-- .github/
|   `-- workflows/
|       |-- ci.yml
|       `-- release.yml
|-- .releaserc.json
`-- tests/
    |-- run-tests.sh
    `-- benchmark.sh
```

## Important Files

- `SKILL.md`: skill entry point, hard gates, routing rules, and project-docs integration.
- `scripts/bootstrap-docs.sh`: idempotent script for seeding Compass docs into a target project. Also creates or updates Compass blocks in agent gateway files — auto-detects `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `COPILOT.md`, `.claude/rules/`, `.cursor/rules/`; falls back to `AGENTS.md`. Use `--skip-agents` to suppress or `--agents-file F` to target a specific file. Also initializes the `docs/.memory/` structure with shared/ and local/ subdirectories. Supports `--validate` to check existing docs without writing, and `--update` for incremental updates with three-way merge (preserves user customizations, detects conflicts).
- `scripts/memory-sync.sh`: detects and imports agent memories from providers like Claude Code, Qoder, and Cursor into `docs/.memory/`. Classifies each memory as shared or local using keyword-based rules from `references/memory-providers.xml` (single source of truth). Validates memory files before import, detects duplicates via content hashing, and supports `--verbose` for detailed audit logging to `docs/.memory/sync-log.json`.
- `scripts/memory-index.sh`: generates a searchable YAML index of project memories. Supports `--scope` filtering (shared/local/all) and `--lifecycle` mode for reporting memory status (active, stale, expired, archived).
- `scripts/resolve-workflows.sh`: validates and merges custom workflow definitions from `docs/process/custom-workflows.xml` with preset workflows. Detects type conflicts, validates structure, and produces merged workflow references.
- `scripts/ci-check.sh`: CI/CD integration script that runs 5 validation checks: bootstrap validation, workflow validation, docs index freshness, link integrity, and policy consistency. Supports `--strict` and `--quiet` modes for pipeline integration.
- `scripts/version.sh`: semantic version management. Shows current version, bumps major/minor/patch, and creates annotated git tags. Reads from `VERSION` file.
- `scripts/docs-index.sh`: prints an on-demand YAML index of a project's docs from note frontmatter so agents load only relevant notes.
- `scripts/skills-check.sh`: reports, without network access, which recommended skills are installed and prints install commands for missing ones.
- `scripts/lib/yaml.sh`: shared YAML quoting for Compass scripts.
- `scripts/smoke-test.sh`: minimal script verification for preset listing, dry-run, failure paths, and no-overwrite behavior.
- `tests/run-tests.sh`: deterministic test wrapper for shell syntax, XML validity, smoke tests, docs links, workflow coverage, policy consistency, update-skill fallback checks, preset bootstrap checks, docs index checks, memory sync checks, workflow resolution checks, and CI check verification.
- `tests/benchmark.sh`: performance benchmarks for Compass scripts at scale (configurable memory and doc counts).
- `references/classification.xml`: decision tree for task classification.
- `references/task-memory.xml`: pre-implementation task memory gate, statuses, lifecycle, resume rules, and template fallback behavior.
- `references/task-types.xml`: task taxonomy and commit hints.
- `references/bootstrap-rules.xml`: bootstrap rules and completion evidence.
- `references/documentation-policy.xml`: docs taxonomy and source-of-truth rules.
- `references/memory-providers.xml`: memory provider locations (Claude Code, Qoder, Cursor) and keyword-based classification rules for shared/local memory sync.
- `references/recommended-skills.xml`: optional skills that strengthen Compass phases.
- `assets/docs-seed/`: base docs and task memory templates copied into `docs/`.
- `assets/orientation-presets/`: architecture, principle, process, and workflow presets.

## When To Use Compass

Use Compass when a task touches:

- new features;
- behavior changes;
- bug fixes;
- refactors;
- architecture or module boundaries;
- databases, migrations, persistence, or data ownership;
- security;
- performance;
- dependencies;
- build, CI, or tooling;
- engineering documentation;
- test strategy;
- release or deployment.

Compass is unnecessary for casual Q&A, general writing, or one-line commands that do not affect behavior, data, architecture, security, or release state.

## Expected Outcome

A Compass-guided task should leave an auditable trail:

- clear task classification;
- Session Update Gate result for the installed Compass skill;
- locked orientation preset;
- workflow source from `docs/process/workflows.xml`;
- approval gates for risky work;
- Task Memory Gate outcome for approved gated design context or long/risky multi-slice work;
- baseline and delta checkpoints for feature updates;
- small implementation slices;
- verification evidence;
- docs updates when boundaries, contracts, or project decisions change.

Compass is not about making agents obedient for its own sake. It is about making engineering decisions visible, reviewable, and repeatable. Code can move fast. Direction still has to be right.
