#!/usr/bin/env bash
set -euo pipefail

# Compass memory sync: detect agent memories from various providers,
# classify them as shared or local, and import into docs/.memory/.

target_dir="$(pwd)"
provider="auto"
dry_run=0
force=0
verbose=0
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
references_dir="$(cd "$script_dir/../references" && pwd)"

usage() {
  cat <<'USAGE'
Usage: memory-sync.sh [--target DIR] [--provider NAME] [--dry-run] [--force] [--verbose]

Detect agent memories from known providers, classify each as shared (team
knowledge) or local (machine-specific), and import into docs/.memory/.

Options:
  --target DIR       Project directory. Defaults to current directory.
  --provider NAME    Provider to import from: claude-code, qoder, cursor, auto.
                     "auto" tries all known providers. Default: auto.
  --dry-run          Show what would be imported without writing files.
  --force            Overwrite existing memory files in docs/.memory/.
  --verbose          Show detailed classification and import decisions.
  --list-providers   List supported providers and their memory locations.
  --help             Show this help.

Audit Trail:
  Sync operations are logged to docs/.memory/sync-log.json when --verbose is used.
  The log records: timestamp, provider, source file, classification, destination, outcome.

Git Worktree Support:
  Memory sync works with git worktrees. Each worktree path is encoded separately
  for provider detection (e.g., Claude Code stores memories per-path). Memories
  are stored in docs/.memory/ which is shared across all worktrees (same git repo).
  Deduplication prevents importing the same memory twice from different worktrees.
USAGE
}

list_providers() {
  cat <<'PROVIDERS'
Supported memory providers:

claude-code
  Location: ~/.claude/projects/{encoded-path}/memory/
  Format:   Markdown files with YAML frontmatter
  Detect:   Encode project path (/ → -), look for memory/ dir

qoder
  Location: ~/Library/Application Support/Qoder/SharedClientCache/
  Format:   Internal indexed format with cached snapshots
  Detect:   Search workingSpace cache for __memories.md files

cursor
  Location: {project}/.cursor/rules/*.mdc
  Format:   MDC (markdown with frontmatter)
  Detect:   Check if .cursor/rules/ exists in project
PROVIDERS
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      [[ $# -ge 2 ]] || { echo "missing value for --target" >&2; exit 2; }
      target_dir="$2"; shift 2 ;;
    --provider)
      [[ $# -ge 2 ]] || { echo "missing value for --provider" >&2; exit 2; }
      provider="$2"; shift 2 ;;
    --dry-run)
      dry_run=1; shift ;;
    --force)
      force=1; shift ;;
    --verbose)
      verbose=1; shift ;;
    --list-providers)
      list_providers; exit 0 ;;
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
shared_dir="$memory_dir/shared"
local_dir="$memory_dir/local"
sync_log="$memory_dir/sync-log.json"

# ===== Audit logging =====
log_sync_entry() {
  local timestamp provider_name source_file classification dest_file outcome details
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  provider_name="$1"
  source_file="$2"
  classification="$3"
  dest_file="$4"
  outcome="$5"
  details="${6:-}"

  # Only log when verbose or when sync-log.json already exists (continue logging)
  if [[ "$verbose" -eq 0 && ! -f "$sync_log" ]]; then
    return
  fi

  # Initialize log file if needed
  if [[ ! -f "$sync_log" ]]; then
    mkdir -p "$(dirname "$sync_log")"
    echo '[' > "$sync_log"
  fi

  # Remove trailing ] from log, append entry, re-add ]
  local entry
  entry="{\"timestamp\":\"$timestamp\",\"provider\":\"$provider_name\",\"source\":\"$(basename "$source_file")\",\"classification\":\"$classification\",\"destination\":\"$(basename "$dest_file" 2>/dev/null || echo "")\",\"outcome\":\"$outcome\""
  if [[ -n "$details" ]]; then
    entry="$entry,\"details\":\"$details\""
  fi
  entry="$entry}"

  # Check if log has entries (not just opening bracket)
  if [[ "$(wc -l < "$sync_log" | tr -d ' ')" -gt 1 ]]; then
    # Remove closing ], add comma after last entry, append new entry
    sed -i '' '$ d' "$sync_log"  # remove last line (])
    echo ',' >> "$sync_log"
  fi
  echo "$entry" >> "$sync_log"
  echo ']' >> "$sync_log"
}

verbose_log() {
  if [[ "$verbose" -eq 1 ]]; then
    echo "  [verbose] $*" >&2
  fi
}

# ===== Classification engine =====
# Reads classification rules from references/memory-providers.xml and applies them.
# This ensures a single source of truth for classification logic.
classify_memory() {
  local file="$1"
  local content
  content="$(cat "$file")"
  
  # Parse classification rules from XML
  # Extract rules in order: local rules first (safety priority), then shared
  local xml_file="$references_dir/memory-providers.xml"
  if [[ ! -f "$xml_file" ]]; then
    echo "ambiguous"
    return
  fi
  
  # Use awk to parse XML and extract rules with their scope and patterns
  # Returns: scope<TAB>pattern (one per line)
  local rules
  rules="$(awk '
    BEGIN { in_rule=0; in_patterns=0; scope="" }
    /<rule scope=/ {
      # Extract scope attribute value
      scope = $0
      gsub(/.*scope="/, "", scope)
      gsub(/".*/, "", scope)
      in_rule = 1
    }
    in_rule && /<patterns>/ { in_patterns = 1 }
    in_rule && in_patterns && /<pattern>/ {
      # Extract pattern content
      line = $0
      gsub(/.*<pattern>/, "", line)
      gsub(/<\/pattern>.*/, "", line)
      print scope "\t" line
    }
    in_rule && /<\/patterns>/ { in_patterns = 0 }
    in_rule && /<\/rule>/ {
      in_rule = 0
      scope = ""
    }
  ' "$xml_file")"
  
  # Apply rules in order (local first for safety, as they appear in XML)
  while IFS=$'\t' read -r scope pattern; do
    [[ -z "$scope" || -z "$pattern" ]] && continue
    if echo "$content" | grep -qiE "$pattern" 2>/dev/null; then
      echo "$scope"
      return
    fi
  done <<< "$rules"
  
  echo "ambiguous"
}

# ===== Slug helper =====
memory_slug() {
  local name="$1"
  # Strip .md, replace non-alphanumeric with -, collapse dashes, trim
  echo "$name" | sed 's/\.md$//' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g;s/^-//;s/-$//'
}

# ===== Validation =====
# Validates a memory file before import.
# Returns 0 if valid, 1 if invalid (with reason on stderr).
validate_memory() {
  local file="$1"
  
  # Check file exists and is readable
  if [[ ! -f "$file" ]]; then
    echo "file not found: $file" >&2
    return 1
  fi
  
  if [[ ! -r "$file" ]]; then
    echo "file not readable: $file" >&2
    return 1
  fi
  
  # Check file is not empty
  if [[ ! -s "$file" ]]; then
    echo "file is empty: $file" >&2
    return 1
  fi
  
  # Extract body (strip frontmatter if present)
  local body
  body="$(awk '
    BEGIN { fm=0 }
    NR==1 && $0=="---" { fm=1; next }
    fm && $0=="---" { fm=0; next }
    fm { next }
    { print }
  ' "$file")"
  
  # Check body is not empty (after stripping whitespace)
  if [[ -z "$(echo "$body" | tr -d '[:space:]')" ]]; then
    echo "file has no content after frontmatter: $file" >&2
    return 1
  fi
  
  return 0
}

# ===== Deduplication =====
# Checks if a memory is a duplicate of an existing one.
# Returns 0 if not duplicate, 1 if duplicate (with details on stdout).
check_duplicate() {
  local src="$1"
  local dest="$2"
  
  # If destination doesn't exist, not a duplicate
  if [[ ! -f "$dest" ]]; then
    return 0
  fi
  
  # Calculate hash of source content (body only, no frontmatter)
  local src_hash
  src_hash="$(awk '
    BEGIN { fm=0 }
    NR==1 && $0=="---" { fm=1; next }
    fm && $0=="---" { fm=0; next }
    fm { next }
    { print }
  ' "$src" | shasum -a 256 | cut -d' ' -f1)"
  
  # Extract source_hash from destination frontmatter
  local dest_hash
  dest_hash="$(awk '
    BEGIN { fm=0 }
    NR==1 && $0=="---" { fm=1; next }
    fm && $0=="---" { exit }
    fm && /^source_hash:/ { sub(/^source_hash:[[:space:]]*/, ""); print; exit }
  ' "$dest")"
  
  # If hashes match, it's a duplicate
  if [[ -n "$dest_hash" && "$src_hash" == "$dest_hash" ]]; then
    echo "duplicate: content matches existing memory at $(basename "$dest")"
    return 1
  fi
  
  # If no source_hash in dest (old format), fall back to content comparison
  if [[ -z "$dest_hash" ]]; then
    local src_body dest_body
    src_body="$(awk '
      BEGIN { fm=0 }
      NR==1 && $0=="---" { fm=1; next }
      fm && $0=="---" { fm=0; next }
      fm { next }
      { print }
    ' "$src" | tr -d '[:space:]')"
    dest_body="$(awk '
      BEGIN { fm=0 }
      NR==1 && $0=="---" { fm=1; next }
      fm && $0=="---" { fm=0; next }
      fm { next }
      { print }
    ' "$dest" | tr -d '[:space:]')"
    
    local src_content_hash dest_content_hash
    src_content_hash="$(echo "$src_body" | shasum -a 256 | cut -d' ' -f1)"
    dest_content_hash="$(echo "$dest_body" | shasum -a 256 | cut -d' ' -f1)"
    
    if [[ "$src_content_hash" == "$dest_content_hash" ]]; then
      echo "duplicate: content matches existing memory at $(basename "$dest")"
      return 1
    fi
  fi
  
  # Content differs - not a duplicate, but file exists
  echo "conflict: file exists with different content at $(basename "$dest")"
  return 0
}

# ===== Import a single memory file =====
import_memory() {
  local src="$1"
  local basename
  basename="$(basename "$src")"
  local slug
  slug="$(memory_slug "$basename")"
  
  # Validate before processing
  if ! validate_memory "$src"; then
    echo "  SKIP (invalid): $basename"
    log_sync_entry "claude-code" "$src" "" "" "skipped" "validation failed"
    return
  fi
  
  local scope
  scope="$(classify_memory "$src")"
  verbose_log "classified $basename as: $scope"

  local dest_dir dest_file
  if [[ "$scope" == "ambiguous" ]]; then
    dest_dir="$shared_dir"
    dest_file="$dest_dir/$slug.md"
    echo "  AMBIGUOUS → shared (review needed): $basename"
  elif [[ "$scope" == "local" ]]; then
    dest_dir="$local_dir"
    dest_file="$dest_dir/$slug.md"
    echo "  LOCAL: $basename → docs/.memory/local/$slug.md"
  else
    dest_dir="$shared_dir"
    dest_file="$dest_dir/$slug.md"
    echo "  SHARED: $basename → docs/.memory/shared/$slug.md"
  fi

  if [[ "$dry_run" -eq 1 ]]; then
    log_sync_entry "claude-code" "$src" "$scope" "$dest_file" "dry-run"
    return
  fi

  # Check for duplicates
  local dup_result
  if ! dup_result="$(check_duplicate "$src" "$dest_file")"; then
    echo "    $dup_result (skipping)"
    log_sync_entry "claude-code" "$src" "$scope" "$dest_file" "duplicate"
    return
  elif [[ -n "$dup_result" && "$force" -ne 1 ]]; then
    echo "    $dup_result (use --force to overwrite)"
    log_sync_entry "claude-code" "$src" "$scope" "$dest_file" "conflict"
    return
  fi

  mkdir -p "$dest_dir"

  # Strip Claude Code YAML frontmatter and rewrite as Compass memory format.
  local body
  body="$(awk '
    BEGIN { fm=0 }
    NR==1 && $0=="---" { fm=1; next }
    fm && $0=="---" { fm=0; next }
    fm { next }
    { print }
  ' "$src")"

  # Extract description from frontmatter if available.
  local desc
  desc="$(awk '
    BEGIN { fm=0 }
    NR==1 && $0=="---" { fm=1; next }
    fm && $0=="---" { exit }
    fm && /^description:/ { sub(/^description:[[:space:]]*"?/, ""); sub(/"?[[:space:]]*$/, ""); print; exit }
  ' "$src")"

  # Extract title from body (first heading or first line).
  local title
  title="$(echo "$body" | awk '
    /^#/ { sub(/^#+[[:space:]]*/, ""); print; exit }
    NF { print; exit }
  ')"
  [[ -z "$title" ]] && title="$(basename "$src" .md)"

  # Calculate hash of source content for deduplication
  local source_hash
  source_hash="$(echo "$body" | shasum -a 256 | cut -d' ' -f1)"

  {
    echo "---"
    echo "type: memory"
    echo "scope: $scope"
    echo "source: claude-code"
    echo "source_hash: $source_hash"
    echo "imported: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    if [[ -n "$desc" ]]; then
      echo "summary: \"$desc\""
    fi
    echo "status: active"
    echo "expires: \"\""
    echo "related: []"
    echo "---"
    echo ""
    echo "# $title"
    echo ""
    echo "## Context"
    echo ""
    echo "$body"
  } > "$dest_file"

  verbose_log "imported $basename → $(basename "$dest_file") (source_hash: ${source_hash:0:12}...)"
  log_sync_entry "claude-code" "$src" "$scope" "$dest_file" "imported" "hash:${source_hash:0:12}"
}

# ===== Provider: Claude Code =====
detect_claude_code() {
  local encoded_path
  # Encode project path: / → -
  encoded_path="$(echo "$target_dir" | sed 's/\//-/g')"

  local claude_home="${HOME}/.claude/projects/${encoded_path}/memory"
  if [[ ! -d "$claude_home" ]]; then
    return 1
  fi

  local files=()
  while IFS= read -r f; do
    # Skip MEMORY.md (index file, not a memory itself)
    [[ "$(basename "$f")" == "MEMORY.md" ]] && continue
    files+=("$f")
  done < <(find "$claude_home" -type f -name '*.md' | sort)

  if [[ ${#files[@]} -eq 0 ]]; then
    return 1
  fi

  echo "Found ${#files[@]} Claude Code memories for this project:"
  echo "  Source: $claude_home"
  echo ""

  local shared_count=0 local_count=0 ambiguous_count=0
  for f in "${files[@]}"; do
    local result
    result="$(import_memory "$f")"
    echo "$result"
    case "$result" in
      *SHARED*) shared_count=$((shared_count + 1)) ;;
      *LOCAL*) local_count=$((local_count + 1)) ;;
      *AMBIGUOUS*) ambiguous_count=$((ambiguous_count + 1)) ;;
    esac
  done

  echo ""
  echo "Summary: shared=$shared_count local=$local_count ambiguous=$ambiguous_count"
  return 0
}

# ===== Provider: Cursor =====
detect_cursor() {
  local cursor_dir="$target_dir/.cursor/rules"
  if [[ ! -d "$cursor_dir" ]]; then
    return 1
  fi

  local files=()
  while IFS= read -r f; do
    files+=("$f")
  done < <(find "$cursor_dir" -type f -name '*.mdc' 2>/dev/null | sort)

  if [[ ${#files[@]} -eq 0 ]]; then
    return 1
  fi

  echo "Found ${#files[@]} Cursor rule files:"
  echo "  Source: $cursor_dir"
  echo ""

  local count=0
  for f in "${files[@]}"; do
    import_memory "$f"
    count=$((count + 1))
  done

  echo ""
  echo "Summary: imported=$count from Cursor rules"
  return 0
}

# ===== Provider: Qoder =====
detect_qoder() {
  local qoder_cache="${HOME}/Library/Application Support/Qoder/SharedClientCache/cache/workingSpace"
  if [[ ! -d "$qoder_cache" ]]; then
    return 1
  fi

  # Qoder caches are per-session; find files that mention this project path.
  local files=()
  while IFS= read -r f; do
    if grep -ql "$target_dir" "$f" 2>/dev/null; then
      files+=("$f")
    fi
  done < <(find "$qoder_cache" -type f -name '*__memories.md' 2>/dev/null | sort)

  if [[ ${#files[@]} -eq 0 ]]; then
    return 1
  fi

  echo "Found ${#files[@]} Qoder memory snapshots:"
  echo "  Source: $qoder_cache"
  echo ""

  local count=0
  for f in "${files[@]}"; do
    import_memory "$f"
    count=$((count + 1))
  done

  echo ""
  echo "Summary: imported=$count from Qoder snapshots"
  return 0
}

# ===== Main =====

# Ensure .memory structure exists.
if [[ "$dry_run" -eq 0 ]]; then
  mkdir -p "$shared_dir" "$local_dir"

  # Ensure .gitignore covers local/.
  gitignore="$target_dir/.gitignore"
  if [[ -f "$gitignore" ]]; then
    if ! grep -qF 'docs/.memory/local/' "$gitignore"; then
      echo "" >> "$gitignore"
      echo "# Compass local memory (machine-specific, not committed)" >> "$gitignore"
      echo "docs/.memory/local/" >> "$gitignore"
      echo "Updated .gitignore with docs/.memory/local/ entry."
    fi
  fi
fi

detected=0

case "$provider" in
  auto)
    echo "=== Scanning for agent memories ==="
    echo ""
    if detect_claude_code; then detected=1; echo ""; fi
    if detect_cursor; then detected=1; echo ""; fi
    if detect_qoder; then detected=1; echo ""; fi
    ;;
  claude-code)
    if ! detect_claude_code; then
      echo "No Claude Code memories found for this project." >&2
      exit 1
    fi
    detected=1
    ;;
  cursor)
    if ! detect_cursor; then
      echo "No Cursor rules found in this project." >&2
      exit 1
    fi
    detected=1
    ;;
  qoder)
    if ! detect_qoder; then
      echo "No Qoder memories found for this project." >&2
      exit 1
    fi
    detected=1
    ;;
  *)
    echo "unknown provider: $provider" >&2
    echo "supported: claude-code, qoder, cursor, auto" >&2
    exit 2
    ;;
esac

if [[ "$detected" -eq 0 ]]; then
  echo "No agent memories found from any provider."
  echo ""
  echo "To initialize Compass project memory from scratch:"
  echo "  mkdir -p docs/.memory/shared docs/.memory/local"
  echo "  # Add docs/.memory/local/ to .gitignore"
  echo "  # Start adding memories as you work with Compass"
fi
