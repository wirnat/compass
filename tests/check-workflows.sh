#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
VERBOSE=false

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

usage() {
  printf 'Usage: %s [--verbose]\n' "${0##*/}"
  printf 'Checks workflow coverage. --verbose prints intentionally unsupported task types.\n'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --verbose)
      VERBOSE=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
  shift
done

contains_line() {
  local haystack="$1"
  local needle="$2"

  printf '%s\n' "$haystack" | grep -Fxq "$needle"
}

extract_task_types() {
  grep -Eo '<task-type id="[^"]+"' "$ROOT_DIR/references/task-types.xml" | sed -E 's/.*id="([^"]+)"/\1/'
}

extract_classified_types() {
  grep -Eo 'type-if-yes="[^"]+"' "$ROOT_DIR/references/classification.xml" | sed -E 's/.*="([^"]+)"/\1/'
}

extract_workflow_types() {
  local file="$1"

  grep -Eo '<workflow type="[^"]+"' "$file" | sed -E 's/.*type="([^"]+)"/\1/'
}

check_unsupported_policy() {
  grep -Fq 'If the selected task type has no matching' "$ROOT_DIR/SKILL.md" \
    && grep -Fq 'Do not silently borrow a workflow from another preset' "$ROOT_DIR/SKILL.md"
}

task_types="$(extract_task_types)"
[ -n "$task_types" ] || fail 'no task types found in references/task-types.xml'

# The taxonomy and the classification decision tree must list the same types.
classified_types="$(extract_classified_types)"
while IFS= read -r type; do
  contains_line "$classified_types" "$type" || fail "task type missing from references/classification.xml decision tree: $type"
done <<< "$task_types"
while IFS= read -r type; do
  contains_line "$task_types" "$type" || fail "classification type not listed in references/task-types.xml: $type"
done <<< "$classified_types"

policy_allows_limited_presets=false
if check_unsupported_policy; then
  policy_allows_limited_presets=true
fi

check_workflow_file() {
  local label="$1"
  local file="$2"
  local workflow_types type missing=""

  [ -f "$file" ] || fail "$label missing workflow file: $file"

  workflow_types="$(extract_workflow_types "$file")"
  [ -n "$workflow_types" ] || fail "$label has no workflow types"

  while IFS= read -r type; do
    [ -n "$type" ] || continue
    contains_line "$task_types" "$type" || fail "$label has workflow type not listed in references/task-types.xml: $type"
  done <<< "$workflow_types"

  while IFS= read -r type; do
    [ -n "$type" ] || continue
    if ! contains_line "$workflow_types" "$type"; then
      missing="$missing $type"
    fi
  done <<< "$task_types"

  if [ -n "$missing" ]; then
    if [ "$policy_allows_limited_presets" = true ]; then
      if [ "$VERBOSE" = true ]; then
        printf 'INFO: %s intentionally lacks workflows:%s\n' "$label" "$missing"
      fi
    else
      fail "$label lacks workflows and SKILL.md has no unsupported-workflow stop policy:$missing"
    fi
  fi
}

check_workflow_file 'repository docs' "$ROOT_DIR/docs/process/workflows.xml"

while IFS= read -r -d '' workflow; do
  preset_dir="${workflow%/docs/process/workflows.xml}"
  check_workflow_file "preset ${preset_dir##*/}" "$workflow"
done < <(find "$ROOT_DIR/assets/orientation-presets" -path '*/docs/process/workflows.xml' -print0)

printf 'Workflow coverage checks passed.\n'
