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
| Completion is claimed by confidence | Completion requires evidence: tests, checks, docs, or a clear reason |

Compass makes agents behave more like disciplined engineering partners. They still move quickly, but their speed is constrained by quality rules the project has already chosen.

## What Compass Provides

Compass gives a project the enforcement points needed to produce higher-quality code:

- **Orientation lock**: the project chooses architecture, principles, and development mechanism before implementation.
- **Engineering philosophy**: daily decisions are guided by maintainability, small scope, readable flow, useful comments, and behavior-focused tests.
- **Ready-to-use presets**: Clean Architecture, Vertical Slice, DDD, existing architecture, or research-based orientation.
- **Project-owned workflow**: the active workflow lives in one place, `docs/process/workflows.xml`.
- **Task memory for long work**: multi-slice tasks can keep a durable `docs/.tasks/` goal, diagram, and memory artifact so future sessions resume from the same goal.
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

1. Check whether the project already has orientation docs under `docs/`.
2. If not, offer orientation presets and bootstrap only after the developer chooses.
3. Seed project docs, including `docs/decisions/0001-orientation-lock.md`.
4. Copy the selected preset workflow to `docs/process/workflows.xml`.
5. Read relevant project docs: orientation lock, architecture, foundation, process, module docs, and decisions.
6. Classify the task by engineering risk, not by wording alone.
7. Run the active workflow from `docs/process/workflows.xml`.
8. Before implementation, run the Task Memory Gate: for long multi-slice work, inspect or create `docs/.tasks/<task>/` after goal alignment and report `created`, `resumed`, or `not-required`.
9. Allow implementation only through the workflow's gates and required evidence.

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
/path/to/installed/compass/scripts/bootstrap-docs.sh --list-presets
/path/to/installed/compass/scripts/bootstrap-docs.sh --target . --preset clean-solid-tdd
```

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
| `new_feature` | Add a new capability |
| `feature_update` | Change existing behavior |
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
|   `-- orientation-presets/
|       `-- <preset>/
|           `-- docs/
|               `-- process/
|                   `-- workflows.xml
|-- references/
|   |-- bootstrap-rules.xml
|   |-- classification.xml
|   |-- documentation-policy.xml
|   `-- task-types.xml
`-- scripts/
    `-- bootstrap-docs.sh
```

## Important Files

- `SKILL.md`: skill entry point, hard gates, routing rules, and project-docs integration.
- `scripts/bootstrap-docs.sh`: idempotent script for seeding Compass docs into a target project.
- `references/classification.xml`: decision tree for task classification.
- `references/task-types.xml`: task taxonomy and commit hints.
- `references/bootstrap-rules.xml`: bootstrap rules and completion evidence.
- `references/documentation-policy.xml`: docs taxonomy and source-of-truth rules.
- `assets/docs-seed/`: base docs always copied into `docs/`.
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
- locked orientation preset;
- workflow source from `docs/process/workflows.xml`;
- approval gates for risky work;
- small implementation slices;
- verification evidence;
- docs updates when boundaries, contracts, or project decisions change.

Compass is not about making agents obedient for its own sake. It is about making engineering decisions visible, reviewable, and repeatable. Code can move fast. Direction still has to be right.
