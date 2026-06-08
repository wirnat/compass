#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
BOOTSTRAP="$SCRIPT_DIR/bootstrap-docs.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/compass-smoke.XXXXXX")"

cleanup() {
  rm -rf "$TMP_ROOT"
}

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

expect_failure() {
  if "$@" >/dev/null 2>&1; then
    fail "expected failure: $*"
  fi
}

trap cleanup EXIT

cd "$ROOT_DIR"

presets="$($BOOTSTRAP --list-presets)"
for preset in clean-solid-tdd vertical-cupid-incremental ddd-solid-bdd existing-architecture-lock research-based; do
  case "$presets" in
    *"$preset"*) ;;
    *) fail "preset list missing $preset" ;;
  esac
done

dry_run_target="$TMP_ROOT/dry-run-target"
"$BOOTSTRAP" --target "$dry_run_target" --preset clean-solid-tdd --dry-run >/dev/null

expect_failure "$BOOTSTRAP" --target "$TMP_ROOT/missing-preset"
expect_failure "$BOOTSTRAP" --target "$TMP_ROOT/unknown-preset" --preset does-not-exist

no_overwrite_target="$TMP_ROOT/no-overwrite-target"
"$BOOTSTRAP" --target "$no_overwrite_target" --preset existing-architecture-lock >/dev/null

sentinel='compass smoke sentinel: do not overwrite'
printf '%s\n' "$sentinel" > "$no_overwrite_target/docs/README.md"
"$BOOTSTRAP" --target "$no_overwrite_target" --preset existing-architecture-lock >/dev/null

content="$(<"$no_overwrite_target/docs/README.md")"
if [ "$content" != "$sentinel" ]; then
  fail 'bootstrap overwrote an existing docs/README.md without --force'
fi

printf 'Smoke tests passed.\n'
