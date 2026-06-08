#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

check_required_file() {
  local path="$1"

  [ -f "$ROOT_DIR/$path" ] || fail "missing required file: $path"
}

check_paths_in_file() {
  local label="$1"
  local base_dir="$2"
  local file="$3"
  local extra_base="${4:-}"
  local ref

  while IFS= read -r ref; do
    [ -n "$ref" ] || continue

    case "$ref" in
      docs/.tasks/*) continue ;;
    esac

    if [ -f "$base_dir/$ref" ]; then
      continue
    fi

    if [ -n "$extra_base" ] && { [ -f "$extra_base/$ref" ] || [ -f "$extra_base/${ref#docs/}" ]; }; then
      continue
    fi

    [ -f "$base_dir/$ref" ] || fail "$label references missing path $ref in ${file#$base_dir/}"
  done < <(awk '/^```/{in_code=!in_code; next} !in_code {print}' "$file" | grep -Eoh 'docs/[A-Za-z0-9._/-]+\.(md|xml)' || true)
}

check_scope() {
  local label="$1"
  local base_dir="$2"
  local extra_base="${3:-}"
  local docs_dir="$base_dir/docs"
  local file

  [ -d "$docs_dir" ] || fail "$label missing docs directory: $docs_dir"

  while IFS= read -r -d '' file; do
    check_paths_in_file "$label" "$base_dir" "$file" "$extra_base"
  done < <(find "$docs_dir" -type f \( -name '*.md' -o -name '*.xml' \) -print0)
}

check_required_file 'assets/docs-seed/_templates/task-goal.md'
check_required_file 'assets/docs-seed/_templates/task-diagram.md'
check_required_file 'assets/docs-seed/_templates/task-memories.md'

check_paths_in_file 'repository docs' "$ROOT_DIR" "$ROOT_DIR/docs/process/workflows.xml"

while IFS= read -r -d '' preset_dir; do
  check_scope "preset ${preset_dir##*/}" "$preset_dir" "$ROOT_DIR/assets/docs-seed"
done < <(find "$ROOT_DIR/assets/orientation-presets" -mindepth 1 -maxdepth 1 -type d -print0)

printf 'Doc link checks passed.\n'
