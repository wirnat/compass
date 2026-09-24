#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
RUN_AGENT=false

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --agent)
      RUN_AGENT=true
      ;;
    -h|--help)
      printf 'Usage: %s [--agent]\n' "${0##*/}"
      printf 'Runs deterministic Compass tests by default. --agent also runs slow agent integration when available.\n'
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
  shift
done

cd "$ROOT_DIR"

bash -n scripts/bootstrap-docs.sh scripts/docs-index.sh scripts/skills-check.sh scripts/lib/yaml.sh \
  scripts/update-skill.sh scripts/smoke-test.sh scripts/memory-sync.sh scripts/memory-index.sh \
  scripts/resolve-workflows.sh scripts/ci-check.sh scripts/version.sh \
  tests/bootstrap-all-presets.sh tests/check-doc-links.sh tests/check-docs-index.sh tests/check-skills-check.sh \
  tests/check-policy-consistency.sh tests/check-update-skill.sh tests/check-workflows.sh tests/check-memory-sync.sh \
  tests/check-resolve-workflows.sh tests/run-tests.sh tests/benchmark.sh

xmllint --noout references/*.xml docs/process/workflows.xml assets/docs-seed/process/custom-workflows.xml assets/orientation-presets/*/docs/process/workflows.xml

./scripts/smoke-test.sh
./tests/check-doc-links.sh
./tests/check-workflows.sh
./tests/check-policy-consistency.sh
./tests/check-update-skill.sh
./tests/bootstrap-all-presets.sh
./tests/check-docs-index.sh
./tests/check-skills-check.sh
./tests/check-memory-sync.sh
./tests/check-resolve-workflows.sh

# CI integration check (--help and basic execution)
./scripts/ci-check.sh --help > /dev/null
./scripts/ci-check.sh --target "$ROOT_DIR" --quiet > /dev/null 2>&1 || true

if command -v git >/dev/null 2>&1; then
  git diff --check
fi

if [ "$RUN_AGENT" = true ]; then
  if [ -x tests/agent/test-compass-routing.sh ]; then
    ./tests/agent/test-compass-routing.sh
  else
    fail 'agent integration requested, but tests/agent/test-compass-routing.sh is missing or not executable'
  fi
fi

printf 'All deterministic tests passed.\n'
