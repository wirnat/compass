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
- **Task Memory Gate**: long or risky multi-slice work must create or resume a durable `docs/.tasks/` goal, diagram, and memory artifact before implementation starts.
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

Presets are not just folder templates. They seed `docs/` with decisions, principles, structure, and workflows that become the agent's operating context.

## How It Works

Compass follows this flow:

1. On the first Compass-guided task in a Codex session, check the installed Compass skill against `https://github.com/wirnat/compass` and update it before continuing when the installed copy is stale.
2. Check whether the project already has orientation docs under `docs/`.
3. If not, offer orientation presets and bootstrap only after the developer chooses.
4. Seed project docs, including `docs/decisions/0001-orientation-lock.md`.
5. Copy the selected preset workflow to `docs/process/workflows.xml`.
6. Read relevant project docs: orientation lock, architecture, foundation, process, module docs, and decisions.
7. Classify the task by engineering risk, not by wording alone.
8. Run the active workflow from `docs/process/workflows.xml`.
9. Before implementation, run the Task Memory Gate: for long multi-slice work, inspect or create `docs/.tasks/<task>/` after goal alignment and report `created`, `resumed`, or `not-required`.
10. Allow implementation only through the workflow's gates and required evidence.

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

When Compass is used as an installed skill, resolve the script relative to the loaded skill directory:

```bash
/path/to/installed/compass/scripts/update-skill.sh --skill-dir /path/to/installed/compass
/path/to/installed/compass/scripts/bootstrap-docs.sh --list-presets
/path/to/installed/compass/scripts/bootstrap-docs.sh --target . --preset clean-solid-tdd
```

The update check uses the GitHub repository as the source of truth. If the
installed skill is stale or has no recorded source revision, the updater refreshes
the skill directory first, then the agent must reload `SKILL.md` before
continuing. Kalau peta baru sudah ada, jangan tetap jalan pakai peta fotokopi
zaman lomba gerak jalan.

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
3. **Task Memory Gate**: before implementation, create or resume `docs/.tasks/<task>/` for long multi-slice work, or state why it is not required.
4. **Implementation**: build one small slice, verify it, then stop for validation.

A request to "build feature X" is not permission to skip brainstorming and design. It is the starting bell, not the finish line.

## Feature Update Workflow

For `feature_update`, Compass protects the existing behavior before changing it.
An update is not a smaller new feature; it is a controlled delta from a known
baseline.

1. **Baseline discovery**: find the owner, current behavior, tests, contracts, docs, commands, and behavior that must not drift.
2. **Delta design**: define old behavior, new behavior, unchanged behavior, regression tests, slices, docs impact, and rollout risk.
3. **Task Memory Gate**: before implementation, create or resume task memory for long, risky, or multi-slice updates, or state why it is not required.
4. **Implementation checkpoints**: build one approved delta slice, verify preserved and changed behavior, then stop for validation.
5. **Rollout cleanup**: close feature flags, dark-launch paths, compatibility paths, docs, runbooks, or rollback notes introduced by the update.

Minor updates can pass through this quickly. Medium and high-risk updates should
not skip baseline and delta approval, because changing old behavior without
knowing what must stay still is how software becomes a cupboard full of cables:
everything is connected, nobody knows why.

## Task Memory Gate

Task memory exists so a long task can survive context loss, session changes, and the natural erosion of attention. Goal is the vision; slices are the missions. Missions may change while the goal remains stable. If the goal changes, Compass treats it as a new goal and supersedes the old task memory.

Compass must run the Task Memory Gate before implementation starts. The gate has three allowed outcomes:

| Outcome | Meaning |
| --- | --- |
| `created` | A new task memory folder was created for the aligned goal. |
| `resumed` | One active relevant task memory folder was loaded and reused. |
| `not-required` | The task is small, single-slice, or below the memory threshold. The agent must state why. |

Task memory is required only when both conditions are true:

1. The task is long or risky, such as `new_feature`, `architecture_change`, a large refactor, or work with meaningful checkpoint risk.
2. After align-context, fit-design, or approved design, there are at least two concrete implementation slices.

When required, Compass creates this structure in the target project before the first implementation edit or command:

```text
docs/.tasks/
`-- <YYYYMMDD-HHMM>_<goal_slug>/
    |-- goal.md
    |-- diagram.md
    `-- memories.md
```

The files have different jobs:

- `goal.md`: goal name, status, description, non-goals, success criteria, slice list, evidence, and links to superseded or successor goals.
- `diagram.md`: Mermaid checkpoint diagram plus text fallback. Pending slices are gray, active is blue, done is green, blocked is red.
- `memories.md`: `SUMMARIES` plus newest-first `HISTORIES`, including user intent, agent rationale snapshot, and agreement. It must not expose private chain-of-thought.

At every slice boundary, Compass updates task memory before reporting the checkpoint. If a slice starts, completes, blocks, or changes, update the same folder. If the goal changes, create a new task folder, mark the old goal `superseded`, cross-link both folders, and record the reason in both `memories.md` files.

Missing task memory templates in the target project do not waive the gate. Compass must use the installed templates or `references/task-memory.xml`, then report the documentation gap. Anak boleh lupa bawa penggaris; tugas menggambar garis lurus tetap ada.

## Automatic Docs Context

Compass treats `docs/` as the project's context pack.

That means a project does not need to copy Compass doc links into `AGENTS.md`. `AGENTS.md` can still hold local agent instructions, but Compass learns the project from `docs/`.

Key docs used by Compass:

- `docs/decisions/0001-orientation-lock.md`
- `docs/process/workflows.xml`
- `docs/architecture/*`
- `docs/foundation/*`
- `docs/process/*`
- `docs/modules/*`
- `docs/decisions/*`
- `docs/reference/*`

If code and docs disagree, Compass should stop before broad changes and call out the conflict. Quietly choosing a side is how architecture turns into folklore.

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
|   |-- task-memory.xml
|   `-- task-types.xml
`-- scripts/
    `-- bootstrap-docs.sh
```

## Important Files

- `SKILL.md`: skill entry point, hard gates, routing rules, and project-docs integration.
- `scripts/bootstrap-docs.sh`: idempotent script for seeding Compass docs into a target project.
- `references/classification.xml`: decision tree for task classification.
- `references/task-memory.xml`: pre-implementation task memory gate, statuses, lifecycle, resume rules, and template fallback behavior.
- `references/task-types.xml`: task taxonomy and commit hints.
- `references/bootstrap-rules.xml`: bootstrap rules and completion evidence.
- `references/documentation-policy.xml`: docs taxonomy and source-of-truth rules.
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
- Task Memory Gate outcome for long or risky multi-slice work;
- baseline and delta checkpoints for feature updates;
- small implementation slices;
- verification evidence;
- docs updates when boundaries, contracts, or project decisions change.

Compass is not about making agents obedient for its own sake. It is about making engineering decisions visible, reviewable, and repeatable. Code can move fast. Direction still has to be right.
