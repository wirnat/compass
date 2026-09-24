#!/usr/bin/env bash
set -euo pipefail

# Compass memory index: generate a searchable YAML index of project memories.

target_dir="$(pwd)"
scope_filter="all"
lifecycle=0
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'USAGE'
Usage: memory-index.sh [--target DIR] [--scope SCOPE] [--lifecycle]

Generate a searchable YAML index of project memories in docs/.memory/.

Options:
  --target DIR      Project directory. Defaults to current directory.
  --scope SCOPE     Filter by scope: shared, local, all. Default: all.
  --lifecycle       Report memory lifecycle status (active, stale, expired, archived).
  --help            Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      [[ $# -ge 2 ]] || { echo "missing value for --target" >&2; exit 2; }
      target_dir="$2"; shift 2 ;;
    --scope)
      [[ $# -ge 2 ]] || { echo "missing value for --scope" >&2; exit 2; }
      scope_filter="$2"; shift 2 ;;
    --lifecycle)
      lifecycle=1; shift ;;
    --help|-h)
      usage; exit 0 ;;
    *)
      echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ ! -d "$target_dir" ]]; then
  echo "target directory not found: $target_dir" >&2
  exit 1
fi
target_dir="$(cd "$target_dir" && pwd)"

memory_dir="$target_dir/docs/.memory"
if [[ ! -d "$memory_dir" ]]; then
  echo "memory directory not found: $memory_dir" >&2
  exit 1
fi

shared_dir="$memory_dir/shared"
local_dir="$memory_dir/local"

# Extract frontmatter field value
get_field() {
  local file="$1"
  local field="$2"
  awk -v field="$field" '
    BEGIN { fm=0 }
    NR==1 && $0=="---" { fm=1; next }
    fm && $0=="---" { exit }
    fm && $0 ~ "^"field":" {
      sub("^"field":[[:space:]]*", "")
      sub("^\"", "")
      sub("\"[[:space:]]*$", "")
      print
      exit
    }
  ' "$file"
}

# Index memories from a directory
index_memories() {
  local dir="$1"
  local scope="$2"
  
  [[ -d "$dir" ]] || return 0
  
  while IFS= read -r file; do
    [[ -f "$file" ]] || continue
    
    local basename
    basename="$(basename "$file")"
    local rel_path
    rel_path="$(echo "$file" | sed "s|^$target_dir/||")"
    
    local source imported summary
    source="$(get_field "$file" "source")"
    imported="$(get_field "$file" "imported")"
    summary="$(get_field "$file" "summary")"
    
    # If no summary, extract first line of body
    if [[ -z "$summary" ]]; then
      summary="$(awk '
        BEGIN { fm=0 }
        NR==1 && $0=="---" { fm=1; next }
        fm && $0=="---" { fm=0; next }
        fm { next }
        NF { print; exit }
      ' "$file")"
    fi
    
    echo "  - path: \"$rel_path\""
    echo "    scope: \"$scope\""
    [[ -n "$source" ]] && echo "    source: \"$source\""
    [[ -n "$imported" ]] && echo "    imported: \"$imported\""
    [[ -n "$summary" ]] && echo "    summary: \"$summary\""
  done < <(find "$dir" -type f -name '*.md' | sort)
}

# Lifecycle check: report memory status, expiration, and staleness
lifecycle_report() {
  local dir="$1"
  local scope="$2"
  local now
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  
  [[ -d "$dir" ]] || return 0
  
  while IFS= read -r file; do
    [[ -f "$file" ]] || continue
    
    local basename rel_path status expires imported
    basename="$(basename "$file")"
    rel_path="$(echo "$file" | sed "s|^$target_dir/||")"
    status="$(get_field "$file" "status")"
    expires="$(get_field "$file" "expires")"
    imported="$(get_field "$file" "imported")"
    
    # Default status if missing
    [[ -z "$status" ]] && status="active"
    
    # Determine lifecycle state
    local state="active"
    if [[ "$status" == "archived" || "$status" == "deprecated" ]]; then
      state="$status"
    elif [[ -n "$expires" && "$expires" != "\"\"" && "$expires" != "" ]]; then
      # Compare expiration date with now
      if [[ "$expires" < "$now" ]]; then
        state="expired"
      fi
    elif [[ -n "$imported" ]]; then
      # Check if older than 90 days (stale heuristic)
      local import_epoch now_epoch diff_days
      import_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$imported" "+%s" 2>/dev/null || echo 0)"
      now_epoch="$(date -u "+%s")"
      if [[ "$import_epoch" -gt 0 ]]; then
        diff_days=$(( (now_epoch - import_epoch) / 86400 ))
        if [[ "$diff_days" -gt 90 ]]; then
          state="stale"
        fi
      fi
    fi
    
    echo "  - path: \"$rel_path\""
    echo "    scope: \"$scope\""
    echo "    status: \"$status\""
    echo "    lifecycle: \"$state\""
    [[ -n "$expires" && "$expires" != "\"\"" ]] && echo "    expires: \"$expires\""
    [[ -n "$imported" ]] && echo "    imported: \"$imported\""
  done < <(find "$dir" -type f -name '*.md' | sort)
}

# Generate index or lifecycle report
if [[ "$lifecycle" -eq 1 ]]; then
  echo "---"
  echo "mode: lifecycle"
  echo "scope: $scope_filter"
  echo "memories:"
  
  shared_count=0
  local_count=0
  
  if [[ "$scope_filter" == "all" || "$scope_filter" == "shared" ]]; then
    if [[ -d "$shared_dir" ]]; then
      lifecycle_report "$shared_dir" "shared"
      shared_count=$(find "$shared_dir" -type f -name '*.md' | wc -l | tr -d ' ')
    fi
  fi
  
  if [[ "$scope_filter" == "all" || "$scope_filter" == "local" ]]; then
    if [[ -d "$local_dir" ]]; then
      lifecycle_report "$local_dir" "local"
      local_count=$(find "$local_dir" -type f -name '*.md' | wc -l | tr -d ' ')
    fi
  fi
  
  echo "---"
  echo "total: $((shared_count + local_count)) (shared=$shared_count local=$local_count)"
else
  # Normal index mode
  echo "---"
  echo "scope: $scope_filter"
  echo "memories:"
  
  shared_count=0
  local_count=0
  
  if [[ "$scope_filter" == "all" || "$scope_filter" == "shared" ]]; then
    if [[ -d "$shared_dir" ]]; then
      index_memories "$shared_dir" "shared"
      shared_count=$(find "$shared_dir" -type f -name '*.md' | wc -l | tr -d ' ')
    fi
  fi
  
  if [[ "$scope_filter" == "all" || "$scope_filter" == "local" ]]; then
    if [[ -d "$local_dir" ]]; then
      index_memories "$local_dir" "local"
      local_count=$(find "$local_dir" -type f -name '*.md' | wc -l | tr -d ' ')
    fi
  fi
  
  echo "---"
  echo "total: $((shared_count + local_count)) (shared=$shared_count local=$local_count)"
fi
