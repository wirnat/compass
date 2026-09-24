#!/usr/bin/env bash
set -euo pipefail

# benchmark.sh — Performance benchmarks for Compass scripts.
#
# Tests key operations at scale to detect performance regressions.
# Creates synthetic projects with many files/memories and measures timing.

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

memory_count=100
doc_count=50
tmp_root=""

usage() {
  cat <<'USAGE'
Usage: benchmark.sh [--memories N] [--docs N]

Run Compass performance benchmarks.

Options:
  --memories N   Number of memory files to create. Default: 100.
  --docs N       Number of doc files to create. Default: 50.
  --help         Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --memories)
      [[ $# -ge 2 ]] || { echo "missing value for --memories" >&2; exit 2; }
      memory_count="$2"; shift 2 ;;
    --docs)
      [[ $# -ge 2 ]] || { echo "missing value for --docs" >&2; exit 2; }
      doc_count="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

cleanup() {
  [[ -n "$tmp_root" && -d "$tmp_root" ]] && rm -rf "$tmp_root"
}
trap cleanup EXIT

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/compass-bench.XXXXXX")"

# Helper: measure command execution time in milliseconds
time_ms() {
  local start end
  start="$(python3 -c 'import time; print(int(time.time() * 1000))' 2>/dev/null || date +%s%3N)"
  eval "$@" > /dev/null 2>&1
  end="$(python3 -c 'import time; print(int(time.time() * 1000))' 2>/dev/null || date +%s%3N)"
  echo $((end - start))
}

# ===== Setup benchmark project =====
echo "=== Compass Performance Benchmarks ==="
echo ""
echo "Configuration: memories=$memory_count docs=$doc_count"
echo ""

bench_target="$tmp_root/bench-project"
mkdir -p "$bench_target/docs/.memory/shared" "$bench_target/docs/.memory/local"

# Generate memory files
echo "Setting up $memory_count memory files..."
for i in $(seq 1 "$memory_count"); do
  scope="shared"
  [[ $((i % 4)) -eq 0 ]] && scope="local"
  
  dir="$bench_target/docs/.memory/$scope"
  cat > "$dir/bench-memory-$i.md" <<EOF
---
type: memory
scope: $scope
source: claude-code
imported: "2026-09-24T10:00:00Z"
summary: "Benchmark memory number $i for performance testing"
status: active
expires: ""
related: []
---

# Benchmark Memory $i

This is memory number $i used for performance benchmarking.
It contains enough content to simulate a realistic memory file.
Module architecture and layer boundaries are important considerations.
EOF
done

# Generate doc files for indexing
echo "Setting up $doc_count doc files..."
mkdir -p "$bench_target/docs/architecture" "$bench_target/docs/modules" "$bench_target/docs/decisions"
for i in $(seq 1 "$doc_count"); do
  cat > "$bench_target/docs/modules/module-note-$i.md" <<EOF
---
type: note
module: "module-$i"
status: active
---

# Module $i Notes

This is module $i documentation with architecture details.
Related to decisions and testing patterns.
EOF
done

echo ""
echo "=== Benchmarks ==="
echo ""

# ===== Benchmark 1: Bootstrap validation =====
ms=$(time_ms "\"$ROOT_DIR/scripts/bootstrap-docs.sh\" --target \"$bench_target\" --validate")
echo "1. Bootstrap --validate ($doc_count docs): ${ms}ms"

# ===== Benchmark 2: Memory index =====
ms=$(time_ms "\"$ROOT_DIR/scripts/memory-index.sh\" --target \"$bench_target\"")
echo "2. Memory index ($memory_count memories): ${ms}ms"

# ===== Benchmark 3: Memory index --lifecycle =====
ms=$(time_ms "\"$ROOT_DIR/scripts/memory-index.sh\" --target \"$bench_target\" --lifecycle")
echo "3. Memory lifecycle ($memory_count memories): ${ms}ms"

# ===== Benchmark 4: Docs index =====
ms=$(time_ms "\"$ROOT_DIR/scripts/docs-index.sh\" --target \"$bench_target\"")
echo "4. Docs index ($doc_count docs): ${ms}ms"

# ===== Benchmark 5: Workflow validation =====
cp "$ROOT_DIR/assets/docs-seed/process/custom-workflows.xml" "$bench_target/docs/process/custom-workflows.xml" 2>/dev/null || true
mkdir -p "$bench_target/docs/process"
cp "$ROOT_DIR/assets/orientation-presets/clean-solid-tdd/docs/process/workflows.xml" "$bench_target/docs/process/workflows.xml" 2>/dev/null || true
ms=$(time_ms "\"$ROOT_DIR/scripts/resolve-workflows.sh\" --target \"$bench_target\" --validate")
echo "5. Workflow validate: ${ms}ms"

# ===== Benchmark 6: CI check =====
ms=$(time_ms "\"$ROOT_DIR/scripts/ci-check.sh\" --target \"$bench_target\" --quiet")
echo "6. CI check (all checks): ${ms}ms"

# ===== Benchmark 7: Bootstrap full =====
bench_new="$tmp_root/bench-new"
ms=$(time_ms "\"$ROOT_DIR/scripts/bootstrap-docs.sh\" --target \"$bench_new\" --preset clean-solid-tdd")
echo "7. Bootstrap full (new project): ${ms}ms"

# ===== Benchmark 8: Incremental update (no changes) =====
ms=$(time_ms "\"$ROOT_DIR/scripts/bootstrap-docs.sh\" --target \"$bench_new\" --preset clean-solid-tdd --update")
echo "8. Incremental update (no changes): ${ms}ms"

echo ""
echo "=== Summary ==="
echo ""
echo "All benchmarks completed. Times in milliseconds."
echo "Lower is better. Re-run with --memories N --docs N to test at different scales."
echo ""
echo "✅ Benchmarks complete."
