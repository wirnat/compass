#!/usr/bin/env bash
set -euo pipefail

target_dir="$(pwd)"
include_all=0
tasks_mode=0

# Task memory stops being cheap to resume beyond these sizes.
goal_line_limit=120
summaries_line_limit=60

usage() {
  cat <<'USAGE'
Usage: docs-index.sh [--target DIR] [--tasks] [--all]

Print a YAML index of DIR/docs Markdown notes built from their frontmatter, so an
agent can choose which docs to load without opening every file. With --tasks,
list task memory goals under DIR/docs/.tasks and warn about structure drift. The
index is generated on demand; do not store or edit it.

Options:
  --target DIR  Project directory to index. Defaults to current directory.
  --tasks       Index docs/.tasks goals instead of docs notes.
  --all         Include superseded and archived notes, or closed goals with --tasks.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      if [[ $# -lt 2 ]]; then
        echo "missing value for --target" >&2
        exit 2
      fi
      target_dir="$2"
      shift 2
      ;;
    --tasks)
      tasks_mode=1
      shift
      ;;
    --all)
      include_all=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ ! -d "$target_dir/docs" ]]; then
  echo "docs directory not found: $target_dir/docs" >&2
  exit 1
fi

cd "$target_dir"

# Shared awk helpers. YAML quoting lives only in q().
awk_lib='
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function unquote(s,   f) {
  f = substr(s, 1, 1)
  if (length(s) >= 2 && (f == "\"" || f == "\047") && substr(s, length(s), 1) == f) return substr(s, 2, length(s) - 2)
  return s
}
function q(s,   out, i, c) {
  out = ""
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (c == "\\" || c == "\"") out = out "\\"
    out = out c
  }
  return "\"" out "\""
}
'

# Parses one note. Emits "S<TAB>status", "C<TAB>glob<TAB>quoted warning" per
# code glob, and "Y<TAB>yaml line" for the index entry. With mode=tasks it reads
# goal_status, updated, and the title of a task goal instead.
awk_prog="$awk_lib"'
function add(key, val) {
  val = unquote(trim(val))
  if (val == "") return
  if (key == "type" || key == "status" || key == "summary" || key == "goal_status" || key == "updated") {
    if (!(key in scalar)) scalar[key] = val
    return
  }
  if (key != "aliases" && key != "related" && key != "code") return
  if (key == "related" && val ~ /^\[\[.*\]\]$/) {
    val = substr(val, 3, length(val) - 4)
    sub(/\|.*/, "", val)
    if (val !~ /\.[A-Za-z0-9]+$/) val = val ".md"
  }
  if (key == "code") codes[++ncode] = val
  list[key] = ((key in list) ? list[key] ", " : "") q(val)
}
NR == 1 && $0 == "---" { fm = 1; next }
fm && $0 == "---" { fm = 0; next }
fm {
  if ($0 ~ /^[A-Za-z_][A-Za-z0-9_-]*:/) {
    cur = $0; sub(/:.*/, "", cur)
    val = $0; sub(/^[^:]*:/, "", val); val = trim(val)
    if (val ~ /^\[.*\]$/) {
      n = split(substr(val, 2, length(val) - 2), parts, ",")
      for (i = 1; i <= n; i++) add(cur, parts[i])
    } else {
      add(cur, val)
    }
  } else if ($0 ~ /^[ \t]+-/) {
    val = $0; sub(/^[ \t]+-/, "", val)
    add(cur, val)
  }
  next
}
/^```/ { fence = !fence; next }
!fence && title == "" && /^# / { title = trim(substr($0, 3)) }
END {
  summary = ("summary" in scalar) ? scalar["summary"] : title
  if (mode == "tasks") {
    status = ("goal_status" in scalar) ? scalar["goal_status"] : ""
    print "S\t" status
    if (status != "") print "Y\t    goal_status: " q(status)
    if ("updated" in scalar) print "Y\t    updated: " q(scalar["updated"])
    if (summary != "") print "Y\t    title: " q(summary)
    exit
  }
  status = ("status" in scalar) ? scalar["status"] : ""
  if (summary == "") { summary = path; sub(/.*\//, "", summary); sub(/\.md$/, "", summary) }
  print "S\t" status
  for (i = 1; i <= ncode; i++) print "C\t" codes[i] "\t" q(path ": code glob matches no files: " codes[i])
  print "Y\t  - path: " q(path)
  if ("type" in scalar) print "Y\t    type: " q(scalar["type"])
  if (status != "") print "Y\t    status: " q(status)
  print "Y\t    summary: " q(summary)
  if ("aliases" in list) print "Y\t    aliases: [" list["aliases"] "]"
  if ("related" in list) print "Y\t    related: [" list["related"] "]"
  if ("code" in list) print "Y\t    code: [" list["code"] "]"
}
'

yaml_quote() {
  YAML_VALUE="$1" awk "$awk_lib"' BEGIN { print q(ENVIRON["YAML_VALUE"]) }'
}

# A code glob is relative to the project root; ** is treated like * because
# find -path lets * match across directories.
glob_matches() {
  local pattern="./${1//\*\*/*}"
  local base="./${1%%[*?[]*}"
  base="${base%/*}"
  [[ -e "$base" ]] || return 1
  [[ -n "$(find "$base" -path "$pattern" -print 2>/dev/null | head -n 1)" ]]
}

entries=""
warnings=""
skipped=0

index_docs() {
  local file status entry globs kind value line

  while IFS= read -r file; do
    status=""
    entry=""
    globs=""
    while IFS=$'\t' read -r kind value; do
      case "$kind" in
        S) status="$value" ;;
        C) globs+="$value"$'\n' ;;
        Y) entry+="$value"$'\n' ;;
      esac
    done < <(awk -v path="$file" "$awk_prog" "$file")

    if [[ "$include_all" -eq 0 && ( "$status" == superseded || "$status" == archived ) ]]; then
      skipped=$((skipped + 1))
      continue
    fi

    entries+="$entry"
    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      glob_matches "${line%%$'\t'*}" || warnings+="  - ${line#*$'\t'}"$'\n'
    done <<< "$globs"
  done < <(find docs -type f -name '*.md' -not -path 'docs/_templates/*' -not -path '*/.*' | LC_ALL=C sort)
}

task_warning() {
  warnings+="  - $(yaml_quote "$1: $2")"$'\n'
}

index_tasks() {
  local name_re='^[0-9]{8}-[0-9]{4}_[A-Za-z0-9._-]+$'
  local dir status entry kind value missing file lines has_summaries has_histories

  [[ -d docs/.tasks ]] || return 0

  while IFS= read -r dir; do
    status=""
    entry=""
    if [[ -f "$dir/goal.md" ]]; then
      while IFS=$'\t' read -r kind value; do
        case "$kind" in
          S) status="$value" ;;
          Y) entry+="$value"$'\n' ;;
        esac
      done < <(awk -v path="$dir/goal.md" -v mode=tasks "$awk_prog" "$dir/goal.md")
    fi

    case "$status" in
      completed|superseded|cancelled)
        if [[ "$include_all" -eq 0 ]]; then
          skipped=$((skipped + 1))
          continue
        fi
        ;;
    esac

    entries+="  - folder: $(yaml_quote "$dir")"$'\n'"$entry"

    missing=""
    for file in goal.md diagram.md memories.md; do
      [[ -f "$dir/$file" ]] || missing+="${missing:+, }$file"
    done
    [[ -z "$missing" ]] || task_warning "$dir" "missing $missing"

    if [[ -f "$dir/goal.md" ]]; then
      case "$status" in
        active|completed|superseded|cancelled) ;;
        '') task_warning "$dir" 'missing goal_status' ;;
        *) task_warning "$dir" "invalid goal_status: $status" ;;
      esac
      lines=$(( $(wc -l < "$dir/goal.md") ))
      (( lines <= goal_line_limit )) || task_warning "$dir" "goal.md has $lines lines (limit $goal_line_limit)"
    fi

    [[ "${dir##*/}" =~ $name_re ]] || task_warning "$dir" 'folder name is not YYYYMMDD-HHMM_slug'

    if [[ -f "$dir/memories.md" ]]; then
      # Everything between SUMMARIES and HISTORIES is read on resume, so extra
      # sections placed there count toward the limit.
      read -r has_summaries has_histories lines < <(awk '
        /^## SUMMARIES[ \t]*$/ { s = 1; seen_s = 1; next }
        /^## HISTORIES[ \t]*$/ { s = 0; seen_h = 1; next }
        s { n++ }
        END { print seen_s + 0, seen_h + 0, n + 0 }
      ' "$dir/memories.md")
      if [[ "$has_summaries" -eq 0 || "$has_histories" -eq 0 ]]; then
        task_warning "$dir" 'memories.md lacks ## SUMMARIES or ## HISTORIES'
      elif (( lines > summaries_line_limit )); then
        task_warning "$dir" "memories.md SUMMARIES has $lines lines (limit $summaries_line_limit)"
      fi
    fi
  done < <(find docs/.tasks -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort)
}

if [[ "$tasks_mode" -eq 1 ]]; then
  index_tasks
  list_key=tasks
else
  index_docs
  list_key=docs
fi

printf '# Generated by Compass scripts/docs-index.sh. Do not store or edit.\n'
if [[ -n "$entries" ]]; then
  printf '%s:\n%s' "$list_key" "$entries"
else
  printf '%s: []\n' "$list_key"
fi
printf 'skipped: %d\n' "$skipped"
if [[ -n "$warnings" ]]; then
  printf 'warnings:\n%s' "$warnings"
fi
