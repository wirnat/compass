# Changelog

All notable changes to Compass are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-09-24

### Added

#### Memory System
- Cross-IDE memory synchronization (`scripts/memory-sync.sh`)
- Memory validation with SHA-256 content hashing for deduplication
- XML-driven classification rules (`references/memory-providers.xml`)
- Memory index with searchable YAML output (`scripts/memory-index.sh`)
- Memory lifecycle management (status, expires, related fields)
- Audit trail with `--verbose` mode and `sync-log.json`
- Lifecycle reporting via `--lifecycle` flag

#### Bootstrap & Workflows
- Bootstrap `--validate` flag for docs quality verification
- Bootstrap `--update` flag with three-way merge (manifest-based)
- Custom workflow support via `custom-workflows.xml`
- Workflow validation and merging (`scripts/resolve-workflows.sh`)

#### CI/CD & Quality
- CI/CD integration script (`scripts/ci-check.sh`)
- GitHub Actions CI workflow (auto-test on push/PR)
- GitHub Actions Release workflow (auto-release on tag push)
- Semantic versioning with `scripts/version.sh`
- Performance benchmarks (`tests/benchmark.sh`)

#### Presets
- clean-solid-tdd
- ddd-solid-bdd
- vertical-cupid-incremental
- existing-architecture-lock
- research-based
- infra-ops

### Documentation
- Comprehensive README with all features documented
- Architecture principles and engineering philosophy
- Testing principles and implementation workflows
