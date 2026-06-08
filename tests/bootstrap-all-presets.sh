#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
BOOTSTRAP="$ROOT_DIR/scripts/bootstrap-docs.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/compass-bootstrap-presets.XXXXXX")"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  rm -rf "$TMP_ROOT"
}

require_file() {
  local path="$1"

  [ -f "$path" ] || fail "missing expected bootstrapped file: $path"
}

check_preset_files() {
  local preset="$1"
  local target="$2"

  require_file "$target/docs/README.md"
  require_file "$target/docs/process/workflows.xml"
  require_file "$target/docs/decisions/0001-orientation-lock.md"
  require_file "$target/docs/_templates/task-goal.md"
  require_file "$target/docs/_templates/task-diagram.md"
  require_file "$target/docs/_templates/task-memories.md"

  xmllint --noout "$target/docs/process/workflows.xml"

  case "$preset" in
    clean-solid-tdd)
      require_file "$target/docs/architecture/clean-architecture.md"
      require_file "$target/docs/architecture/folder-file-structure.md"
      require_file "$target/docs/foundation/solid-principles.md"
      require_file "$target/docs/process/tdd-workflow.md"
      ;;
    vertical-cupid-incremental)
      require_file "$target/docs/architecture/vertical-slice-architecture.md"
      require_file "$target/docs/architecture/feature-slice-structure.md"
      require_file "$target/docs/foundation/cupid-yagni-principles.md"
      require_file "$target/docs/process/incremental-test-workflow.md"
      ;;
    ddd-solid-bdd)
      require_file "$target/docs/architecture/domain-driven-design.md"
      require_file "$target/docs/architecture/bounded-context-structure.md"
      require_file "$target/docs/foundation/domain-modeling-principles.md"
      require_file "$target/docs/process/bdd-tdd-workflow.md"
      ;;
    existing-architecture-lock)
      require_file "$target/docs/architecture/existing-architecture-lock.md"
      require_file "$target/docs/foundation/existing-principles-lock.md"
      require_file "$target/docs/process/existing-process-lock.md"
      ;;
    research-based)
      require_file "$target/docs/architecture/research-based-architecture.md"
      require_file "$target/docs/foundation/research-based-principles.md"
      require_file "$target/docs/process/research-based-development-workflow.md"
      ;;
    *)
      fail "unknown preset in test: $preset"
      ;;
  esac
}

trap cleanup EXIT

for preset in clean-solid-tdd vertical-cupid-incremental ddd-solid-bdd existing-architecture-lock research-based; do
  target="$TMP_ROOT/$preset"
  "$BOOTSTRAP" --target "$target" --preset "$preset" >/dev/null
  check_preset_files "$preset" "$target"
done

printf 'Bootstrap-all-presets checks passed.\n'
