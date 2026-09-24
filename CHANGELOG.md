# Changelog

All notable changes to Compass are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

# [1.2.0](https://github.com/wirnat/compass/compare/v1.1.1...v1.2.0) (2026-09-24)


### Features

* add docs-index --match, slim gateway block ([ed410b4](https://github.com/wirnat/compass/commit/ed410b44c371bc2ef6315fdd8edde68184e1c4ab))

## [1.1.1](https://github.com/wirnat/compass/compare/v1.1.0...v1.1.1) (2026-09-24)


### Bug Fixes

* remove ci-check.sh from Compass CI workflow ([f69cc4b](https://github.com/wirnat/compass/commit/f69cc4b70a9bfa5eaa8abf666e57cd95cd4ba69b))

# [1.1.0](https://github.com/wirnat/compass/compare/v1.0.0...v1.1.0) (2026-09-24)


### Features

* add version-aware update with --tag option ([e5ef764](https://github.com/wirnat/compass/commit/e5ef764459140bce43112bcc78e10b6d0c0d4310))

# 1.0.0 (2026-09-24)


### Bug Fixes

* **compass:** align task memory workflow ordering ([0d130a7](https://github.com/wirnat/compass/commit/0d130a7c0c9baa2f2909e3a376b411105d9b5a96))
* **compass:** enforce task memory gate ([fb127b7](https://github.com/wirnat/compass/commit/fb127b72f15ed3697fc770f482570e54554ddb44))
* **compass:** sync seed task memory templates ([4d6ddb5](https://github.com/wirnat/compass/commit/4d6ddb5e95913abfe83a4cb9a37c5ac74b969216))
* install semantic-release plugins in CI workflow ([6385a18](https://github.com/wirnat/compass/commit/6385a1845702ce28da88b8a3460aeb3f8c0623f1))


### Features

* add CI/CD pipeline with semantic-release and versioning ([05c5a9a](https://github.com/wirnat/compass/commit/05c5a9ad956420a6af84cd7dd8c425f1162a739e))
* **compass:** add deterministic checks and align gates ([07538a5](https://github.com/wirnat/compass/commit/07538a597cfa38045c2f1d7e4c519b44b598afbf))
* **compass:** add infra_change task type ([787e9dc](https://github.com/wirnat/compass/commit/787e9dc86b6f05d24c2b842c6a4de8a8d6d9a5e7))
* **compass:** add infra-ops orientation preset ([0c67bc9](https://github.com/wirnat/compass/commit/0c67bc9fe464a02f570ab4d29216958608afea98))
* **compass:** add live environment gate ([f8c278a](https://github.com/wirnat/compass/commit/f8c278ad0197bc034e56ce07c8958e04d89402c6))
* **compass:** add local runtime policy ([5bd7dad](https://github.com/wirnat/compass/commit/5bd7dad0b0e0b5b62557641763914615c2cdb0e9))
* **compass:** add local verification principles ([d980eee](https://github.com/wirnat/compass/commit/d980eeebcb1b0a687d6aca8872776037f376f43c))
* **compass:** add on-demand docs index script ([4a31464](https://github.com/wirnat/compass/commit/4a31464e540e49cf2f197ef77604dda150258967))
* **compass:** add optional Do and Don't guardrails ([d6e1c6f](https://github.com/wirnat/compass/commit/d6e1c6f8eddb212c0719b19b0af5d94aaf3a1cf0))
* **compass:** add recommended skills manifest and check ([06c0a05](https://github.com/wirnat/compass/commit/06c0a05261fa765a2537a10ecccc2a0b7e774fc1))
* **compass:** add summary and code note fields ([7e514c3](https://github.com/wirnat/compass/commit/7e514c3053570d65af60a7f0b5bc48595e1c3bda))
* **compass:** add task close-out and tracking rules ([92acc1f](https://github.com/wirnat/compass/commit/92acc1fca34d74aea9498eb82c9eba64e217c5ac))
* **compass:** add task memory reference ([215fb1b](https://github.com/wirnat/compass/commit/215fb1b81c73876dc53dd63275f60d48a018f8ed))
* **compass:** add task memory templates ([042b76e](https://github.com/wirnat/compass/commit/042b76ec90d927a35e1360a177407db282df9138))
* **compass:** allow linked task supporting files ([2ccafe9](https://github.com/wirnat/compass/commit/2ccafe9ade4a0174352cadea5d28e3b58c029700))
* **compass:** default documentation language to English ([50d111a](https://github.com/wirnat/compass/commit/50d111ad1735e3df59804f8885b3df82cb28ac0b))
* **compass:** enforce standard task memory headings ([c84f10a](https://github.com/wirnat/compass/commit/c84f10a44f82bc212e64cca514eb073194f2202b))
* **compass:** index and lint task memory goals ([1231530](https://github.com/wirnat/compass/commit/12315309298715b0f8b935a73f05e27007d3e791))
* **compass:** lint task close-out and tracking ([7dc1654](https://github.com/wirnat/compass/commit/7dc165487f955eaa54d52e298c5a6181a0afd7a1))
* **compass:** load project docs through the docs index ([4f51e26](https://github.com/wirnat/compass/commit/4f51e26d87a4a9dc11e0f4b5472cb56acea18be9))
* **compass:** persist design context in task memory ([c747d3f](https://github.com/wirnat/compass/commit/c747d3f73a442e76a96016f5d5b0948b6682021d))
* **compass:** require static checks and guide code intelligence ([6644256](https://github.com/wirnat/compass/commit/664425677c49aba4a9c7d7899b0de30080abb5b1))
* **compass:** run the recommended skills check after updates ([a2f2bcb](https://github.com/wirnat/compass/commit/a2f2bcb55831f8302a5c41f645024c4b6bf20df9))
* **compass:** warn about unlinked task supporting files ([757c303](https://github.com/wirnat/compass/commit/757c3032f4417fcffea4f3edd1239c7f5677f9d8))
* **compass:** wire task memory workflow ([30a9841](https://github.com/wirnat/compass/commit/30a9841a1d312dc11f8c320e5280450e30bcaa3e))
* implement comprehensive system improvements (Phase 1-3) ([1206405](https://github.com/wirnat/compass/commit/1206405a380f5e775cb2c05c730512a8ece196aa))
* **skills:** add session update gate and feature-update delta workflows ([c532e4c](https://github.com/wirnat/compass/commit/c532e4cbaf39303437ef88d969d598ffcd3f7b03))

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
