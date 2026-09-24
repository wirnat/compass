#!/usr/bin/env bash
set -euo pipefail

# ci-check.sh — CI/CD integration for Compass docs validation.
#
# Runs a battery of checks suitable for CI pipelines:
#   1. Bootstrap validation (--validate)
#   2. Custom workflow validation
#   3. Docs index freshness
#   4. Link integrity
#   5. Policy consistency
#
# Exit codes:
#   0 — all checks passed
#   1 — one or more checks failed
#   2 — usage error

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

target_dir="$(pwd)"
strict=0
quiet=0
checks_run=0
checks_passed=0
checks_failed=0
checks_skipped=0

usage() {
  cat <<'USAGE'
Usage: ci-check.sh [--target DIR] [--strict] [--quiet]

Run Compass CI checks on a project.

Options:
  --target DIR   Project directory. Defaults to current directory.
  --strict       Treat warnings as failures.
  --quiet        Only show failures and summary.
  --help         Show this help.

Checks performed:
  1. Bootstrap validation  — required files, XML, orientation, gateways
  2. Custom workflows      — structure, conflicts, completeness
  3. Docs index freshness  — docs-index.sh output matches current docs
  4. Link integrity        — internal doc links are valid
  5. Policy consistency    — classification rules, documentation policy

CI Examples:
  # GitHub Actions
  - run: ./path/to/compass/scripts/ci-check.sh --target .

  # GitLab CI
  script:
    - ./path/to/compass/scripts/ci-check.sh --target . --strict

  # With Compass installed as a skill
  - run: compass/scripts/ci-check.sh
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      [[ $# -lt 2 ]] && { echo "missing value for --target" >&2; exit 2; }
      target_dir="$2"; shift 2 ;;
    --strict)
      strict=1; shift ;;
    --quiet)
      quiet=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ ! -d "$target_dir" ]]; then
  echo "target directory not found: $target_dir" >&2
  exit 2
fi
target_dir="$(cd "$target_dir" && pwd)"

log() {
  if [[ "$quiet" -eq 0 ]]; then
    echo "$@"
  fi
}

run_check() {
  local name="$1"
  local cmd="$2"
  checks_run=$((checks_run + 1))

  log ""
  log "--- Check $checks_run: $name ---"

  local output exit_code=0
  output="$(eval "$cmd" 2>&1) || exit_code=$?"

  if [[ "$exit_code" -eq 0 ]]; then
    checks_passed=$((checks_passed + 1))
    log "✅ PASS: $name"
    if [[ "$quiet" -eq 0 ]]; then
      echo "$output" | head -20
      local line_count
      line_count="$(echo "$output" | wc -l | tr -d ' ')"
      if [[ "$line_count" -gt 20 ]]; then
        log "  ... ($line_count lines total)"
      fi
    fi
  else
    checks_failed=$((checks_failed + 1))
    echo "❌ FAIL: $name"
    echo "$output"
  fi

  return "$exit_code"
}

skip_check() {
  local name="$1"
  local reason="$2"
  checks_run=$((checks_run + 1))
  checks_skipped=$((checks_skipped + 1))
  log ""
  log "--- Check $checks_run: $name ---"
  log "⏭️  SKIP: $name ($reason)"
}

# Track overall failure but continue all checks
overall_exit=0

# ===== Check 1: Bootstrap Validation =====
if [[ -f "$target_dir/docs/README.md" ]] && [[ -d "$target_dir/docs" ]]; then
  run_check "Bootstrap validation" \
    "\"$ROOT_DIR/scripts/bootstrap-docs.sh\" --target \"$target_dir\" --validate" \
    || overall_exit=1
else
  skip_check "Bootstrap validation" "no docs/ directory found"
fi

# ===== Check 2: Custom Workflow Validation =====
if [[ -f "$ROOT_DIR/scripts/resolve-workflows.sh" ]]; then
  if [[ -f "$target_dir/docs/process/workflows.xml" ]]; then
    run_check "Custom workflow validation" \
      "\"$ROOT_DIR/scripts/resolve-workflows.sh\" --target \"$target_dir\" --validate" \
      || overall_exit=1
  else
    skip_check "Custom workflow validation" "no workflows.xml found"
  fi
else
  skip_check "Custom workflow validation" "resolve-workflows.sh not found"
fi

# ===== Check 3: Docs Index Freshness =====
if [[ -f "$ROOT_DIR/scripts/docs-index.sh" ]] && [[ -d "$target_dir/docs" ]]; then
  # Check if docs-index.yaml exists and is up to date
  if [[ -f "$target_dir/docs/docs-index.yaml" ]]; then
    # Generate fresh index and compare
    fresh_index="$(mktemp)"
    "$ROOT_DIR/scripts/docs-index.sh" --target "$target_dir" > "$fresh_index" 2>/dev/null || true

    if diff -q "$fresh_index" "$target_dir/docs/docs-index.yaml" > /dev/null 2>&1; then
      checks_run=$((checks_run + 1))
      checks_passed=$((checks_passed + 1))
      log ""
      log "--- Check $checks_run: Docs index freshness ---"
      log "✅ PASS: Docs index is up to date"
    else
      checks_run=$((checks_run + 1))
      checks_failed=$((checks_failed + 1))
      log ""
      log "--- Check $checks_run: Docs index freshness ---"
      echo "❌ FAIL: Docs index is stale"
      echo "Run: scripts/docs-index.sh --target $target_dir"
      overall_exit=1
    fi
    rm -f "$fresh_index"
  else
    skip_check "Docs index freshness" "no docs-index.yaml found (run docs-index.sh first)"
  fi
else
  skip_check "Docs index freshness" "docs-index.sh not found or no docs/"
fi

# ===== Check 4: Link Integrity =====
if [[ -f "$ROOT_DIR/tests/check-doc-links.sh" ]] && [[ -d "$target_dir/docs" ]]; then
  run_check "Link integrity" \
    "\"$ROOT_DIR/tests/check-doc-links.sh\"" \
    || overall_exit=1
else
  skip_check "Link integrity" "check-doc-links.sh not found or no docs/"
fi

# ===== Check 5: Policy Consistency =====
if [[ -f "$ROOT_DIR/tests/check-policy-consistency.sh" ]]; then
  run_check "Policy consistency" \
    "\"$ROOT_DIR/tests/check-policy-consistency.sh\"" \
    || overall_exit=1
else
  skip_check "Policy consistency" "check-policy-consistency.sh not found"
fi

# ===== Summary =====
log ""
log "========================================="
log "  Compass CI Check Summary"
log "========================================="
log ""
log "Target: $target_dir"
log "Mode:   $([ "$strict" -eq 1 ] && echo 'strict' || echo 'normal')"
log ""
log "Checks run:     $checks_run"
log "Checks passed:  $checks_passed"
log "Checks failed:  $checks_failed"
log "Checks skipped: $checks_skipped"
log ""

if [[ "$checks_failed" -gt 0 ]]; then
  echo "❌ CI FAILED: $checks_failed check(s) failed"
  exit 1
elif [[ "$strict" -eq 1 && "$checks_skipped" -gt 0 ]]; then
  echo "⚠️  CI FAILED (strict mode): $checks_skipped check(s) skipped"
  exit 1
else
  echo "✅ CI PASSED: $checks_passed check(s) passed, $checks_skipped skipped"
  exit 0
fi
