---
type: process
status: active
owner: engineering
created: 2026-06-08
updated: 2026-06-08
parent: "[[docs/process/README]]"
tags:
  - docs/process
  - status/active
aliases:
  - Compass testing strategy
related:
  - "[[docs/process/existing-process-lock]]"
---

# Compass Testing Strategy

Compass is a skill package, not an application runtime. Its tests should protect
the behavior that can regress: shell scripts, packaged docs, XML references,
workflow coverage, policy consistency, and agent-facing gate behavior.

Use the cheapest deterministic tests first. Add headless agent integration tests
only after the deterministic checks are stable and there is a specific behavior
that cannot be verified by scripts or static checks.

## Test Layers

| Layer | Purpose | Speed | Default Command |
| --- | --- | --- | --- |
| Shell smoke | Check bootstrap happy paths and failure paths. | Fast | `./scripts/smoke-test.sh` |
| Static validity | Ensure shell syntax and XML files are parseable. | Fast | `bash -n ...` and `xmllint --noout ...` |
| Referential integrity | Ensure docs referenced by presets and workflows exist. | Fast | `./tests/check-doc-links.sh` |
| Workflow coverage | Ensure every task type has a workflow or an explicit unsupported-workflow policy. | Fast | `./tests/check-workflows.sh` |
| Policy consistency | Ensure core gates do not drift across `SKILL.md`, `README.md`, references, and presets. | Fast | `./tests/check-policy-consistency.sh` |
| Update gate | Ensure the fallback updater handles local fixtures without network. | Fast | `./tests/check-update-skill.sh` |
| Docs index | Ensure the docs index covers every preset doc and handles frontmatter edge cases. | Fast | `./tests/check-docs-index.sh` |
| Agent integration | Run a real headless agent session and verify transcript behavior. | Slow | Future `tests/agent/test-compass-routing.sh` |

## Current Baseline

The current executable test baseline is:

```bash
./tests/run-tests.sh
```

`scripts/smoke-test.sh` covers:

- all required presets appear in `--list-presets`
- dry-run succeeds for a known preset
- missing `--preset` fails
- unknown preset fails
- existing docs are not overwritten without `--force`

## Deterministic Test Scripts

Maintain these before adding headless agent tests.

### `tests/check-doc-links.sh`

Purpose: detect broken internal docs paths in preset workflows and orientation
docs.

Minimum checks:

- Paths like `docs/architecture/*.md`, `docs/foundation/*.md`, and
  `docs/process/*.md` mentioned inside each preset exist under that preset's
  `docs/` folder.
- Paths mentioned in this repository's `docs/process/workflows.xml` exist under
  this repository's `docs/` folder.
- Known generated task memory templates exist in `assets/docs-seed/_templates/`.

This would have caught the old `researched-principles.md` and
`researched-workflow.md` mismatch.

### `tests/check-workflows.sh`

Purpose: make workflow support explicit.

Minimum checks:

- Read task types from `references/classification.xml` or
  `references/task-types.xml`.
- Read workflow types from each `assets/orientation-presets/*/docs/process/workflows.xml`.
- Report which task types each preset supports when run with `--verbose`.
- Pass when a preset either defines the task workflow or the global policy in
  `SKILL.md` says missing workflow types must stop and ask for adaptation.
- Fail if a preset or policy implies fallback behavior from another workflow
  source.

This keeps limited presets valid without forcing every preset to copy all 16
task workflows.

### `tests/check-policy-consistency.sh`

Purpose: prevent gate drift across documentation surfaces.

Minimum checks:

- `SKILL.md`, `README.md`, `references/task-memory.xml`, and preset workflows
  all mention Task Memory Gate outcomes: `created`, `resumed`, `not-required`.
- Gated design context is preserved before implementation even when there is one
  approved implementation slice.
- `npx skills update` and `scripts/update-skill.sh --skill-dir` both appear in
  the Session Update Gate docs.
- No stale phrases remain for old rules, such as task memory being required only
  when both long/risky and 2+ slices are true.
- Every `assets/docs-seed/` file matches its `docs/` counterpart, except the
  intentionally customized `docs/README.md` and `docs/reference/README.md`, so
  shipped templates cannot fall behind this repository's own copy.
- The seed task templates contain every heading listed under
  `required-headings` in `references/task-memory.xml`.

### `tests/check-update-skill.sh`

Purpose: test the bundled Session Update Gate fallback without network access.

Minimum checks:

- Create a local source git repository fixture.
- Verify `--check` reports up-to-date when `.compass-source-revision` matches the local source revision.
- Verify a stale non-git skill directory is replaced from the local source repo.
- Verify invalid skill directories and missing branches fail clearly.

### `tests/bootstrap-all-presets.sh`

Purpose: verify each preset can bootstrap into an empty target.

Minimum checks:

- Bootstrap every preset into a separate temp project.
- Verify required seed docs exist.
- Verify preset-specific orientation docs exist.
- Verify `docs/process/workflows.xml` exists and is valid XML.
- Verify task memory templates exist.

This stays separate from `scripts/smoke-test.sh` so the smoke test remains a
small bootstrap-focused check.

### `tests/check-docs-index.sh`

Purpose: keep `scripts/docs-index.sh` output complete and parseable.

Minimum checks:

- Every non-template doc from each preset bootstrap is indexed exactly once,
  without warnings.
- `summary` wins over the first heading; the first heading and then the file
  name are fallbacks.
- Notes without frontmatter list only path and summary.
- Superseded and archived notes are skipped and counted unless `--all` is
  passed.
- `_templates/` and hidden folders such as `.tasks/` are excluded.
- Wikilinks in `related` become `.md` paths; block and inline lists give the
  same output.
- A `code` glob that matches no files produces a warning without failing.
- Quotes, colons, and hashes in values stay valid YAML.
- A missing docs directory exits 1; a missing option value exits 2.
- `--tasks` lists open goals with folder, `goal_status`, `updated`, and title,
  skips completed, superseded, and cancelled goals unless `--all` is passed,
  and prints `tasks: []` when `docs/.tasks/` is missing.
- `--tasks` warns about missing task files, missing or invalid `goal_status`,
  folder names that are not `YYYYMMDD-HHMM_slug`, missing Compass-required
  headings (matched case-insensitively), and `goal.md` or the `SUMMARIES`
  region over their limits. Limits are inclusive.
- Project template headings are not enforced; they only end the `SUMMARIES`
  region, so sections outside the project template count toward the limit.

## Agent Integration Tests

Use Superpowers-style headless transcript tests only for behavior that depends
on the agent following `SKILL.md`.

Recommended first integration test:

### `tests/agent/test-compass-routing.sh`

Scenario:

1. Create a temp project with no Compass docs.
2. Run a headless agent prompt from the Compass repository.
3. Ask for a small feature request.
4. Verify the transcript shows Compass skill usage, Session Update Gate handling,
   preset selection or bootstrap gate, classification, workflow source, and an
   approval stop before implementation.

Verify from session transcript, not from user-facing text alone:

- Skill was invoked.
- Update gate was attempted or explicitly reported as skipped by test setup.
- Bootstrap did not silently choose a preset unless existing architecture
  evidence justified it.
- Classification output used the XML routing shape.
- Implementation did not start before required approval gates.

Do not run this test by default. It is slow, requires a working agent CLI,
depends on external credentials or local session configuration, and may cost
tokens.

## Default Test Command Policy

Keep the default test command lightweight:

```bash
./tests/run-tests.sh
```

The wrapper runs shell syntax checks, XML checks, smoke tests, and deterministic
`tests/check-*.sh` scripts. It does not run slow agent integration tests unless
passed an explicit flag such as `--agent`.

## Acceptance Criteria

A testing change is complete when:

- The default test command is documented in `docs/process/existing-process-lock.md`.
- New tests use temp directories and clean them with `trap`.
- Tests do not require network unless their name clearly says so.
- Tests do not write outside the repository or approved temp directory.
- Tests fail with clear `FAIL: ...` messages.
- Agent integration tests are optional and documented as slow.
