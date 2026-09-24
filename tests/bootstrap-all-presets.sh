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
  require_file "$target/docs/_templates/local-environment.md"

  # .memory/ structure must be created.
  [ -d "$target/docs/.memory/shared" ] || fail "missing docs/.memory/shared/ for preset $preset"
  [ -d "$target/docs/.memory/local" ] || fail "missing docs/.memory/local/ for preset $preset"
  require_file "$target/docs/.memory/README.md"

  # AGENTS.md must be created with a Compass block.
  require_file "$target/AGENTS.md"
  grep -qF '<!-- compass:start -->' "$target/AGENTS.md" \
    || fail "AGENTS.md lacks <!-- compass:start --> marker for preset $preset"
  grep -qF '<!-- compass:end -->' "$target/AGENTS.md" \
    || fail "AGENTS.md lacks <!-- compass:end --> marker for preset $preset"

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
    infra-ops)
      require_file "$target/docs/architecture/infrastructure-layout.md"
      require_file "$target/docs/foundation/operations-principles.md"
      require_file "$target/docs/process/change-workflow.md"
      grep -Fq '<workflow type="infra_change"' "$target/docs/process/workflows.xml" \
        || fail 'infra-ops workflows.xml lacks the infra_change workflow'
      grep -Fq '<risk-tiering>' "$target/docs/process/workflows.xml" \
        || fail 'infra-ops workflows.xml lacks risk-tiering'
      ;;
    *)
      fail "unknown preset in test: $preset"
      ;;
  esac
}

trap cleanup EXIT

for preset in clean-solid-tdd vertical-cupid-incremental ddd-solid-bdd existing-architecture-lock research-based infra-ops; do
  target="$TMP_ROOT/$preset"
  "$BOOTSTRAP" --target "$target" --preset "$preset" >/dev/null
  check_preset_files "$preset" "$target"
done

# ===== Incremental Update Tests =====

update_target="$TMP_ROOT/update-test"
"$BOOTSTRAP" --target "$update_target" --preset clean-solid-tdd >/dev/null

# Manifest must exist after bootstrap.
[ -f "$update_target/docs/.compass-manifest" ] || fail 'manifest missing after bootstrap'

# Manifest must have entries.
manifest_lines=$(wc -l < "$update_target/docs/.compass-manifest" | tr -d ' ')
[ "$manifest_lines" -gt 0 ] || fail 'manifest is empty'

# --update with no changes should report all unchanged.
output=$("$BOOTSTRAP" --target "$update_target" --preset clean-solid-tdd --update 2>&1)
echo "$output" | grep -qF 'Unchanged:' || fail '--update missing unchanged count'
echo "$output" | grep -qF 'Added: 0' || fail '--update should report 0 added when nothing changed'
echo "$output" | grep -qF 'Updated: 0' || fail '--update should report 0 updated when nothing changed'
echo "$output" | grep -qF 'Conflicts: 0' || fail '--update should report 0 conflicts when nothing changed'

# User modifies a file → should be preserved.
echo '# user customization' >> "$update_target/docs/foundation/engineering-philosophy.md"
output=$("$BOOTSTRAP" --target "$update_target" --preset clean-solid-tdd --update 2>&1)
echo "$output" | grep -qF 'PRESERVE' || fail '--update should PRESERVE user-modified file'
echo "$output" | grep -qF 'Preserved (user modified): 1' || fail '--update should report 1 preserved'

# Verify user content still there.
grep -qF '# user customization' "$update_target/docs/foundation/engineering-philosophy.md" \
  || fail 'user customization lost after --update'

# --update without manifest should fail.
no_manifest="$TMP_ROOT/no-manifest"
mkdir -p "$no_manifest/docs"
"$BOOTSTRAP" --target "$no_manifest" --preset clean-solid-tdd >/dev/null 2>&1
rm -f "$no_manifest/docs/.compass-manifest"
code=0
"$BOOTSTRAP" --target "$no_manifest" --preset clean-solid-tdd --update >/dev/null 2>&1 || code=$?
[ "$code" -eq 1 ] || fail '--update without manifest should exit 1'

# --dry-run with --update should not write.
dry_target="$TMP_ROOT/dry-update"
"$BOOTSTRAP" --target "$dry_target" --preset clean-solid-tdd >/dev/null
echo '# dry test' >> "$dry_target/docs/foundation/testing-principles.md"
output=$("$BOOTSTRAP" --target "$dry_target" --preset clean-solid-tdd --update --dry-run 2>&1)
echo "$output" | grep -qF 'PRESERVE' || fail '--dry-run --update should show PRESERVE'
# File should still have user modification (no actual write).
grep -qF '# dry test' "$dry_target/docs/foundation/testing-principles.md" \
  || fail '--dry-run --update should not modify files'

printf 'Bootstrap-all-presets checks passed.\n'
