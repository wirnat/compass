#!/usr/bin/env bash
set -euo pipefail

target_dir="$(pwd)"
include_all=0
tasks_mode=0
match_keywords=""
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/yaml.sh
source "$script_dir/lib/yaml.sh"

# Task memory stops being cheap to resume beyond these sizes.
goal_line_limit=120
summaries_line_limit=60

usage() {
  cat <<'USAGE'
Usage: docs-index.sh [--target DIR] [--tasks] [--all] [--match KEYWORDS]

Print a YAML index of DIR/docs Markdown notes built from their frontmatter, so an
agent can choose which docs to load without opening every file. With --tasks,
list task memory goals under DIR/docs/.tasks and warn about structure drift. The
index is generated on demand; do not store or edit it.

Options:
  --target DIR  Project directory to index. Defaults to current directory.
  --tasks       Index docs/.tasks goals instead of docs notes.
  --all         Include superseded and archived notes, or closed goals with --tasks.
  --match KEYWORDS
                Comma-separated keywords; keep only entries whose text contains
                at least one keyword (case-insensitive) and report match/matched
                metadata so an agent loads just the relevant notes.
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
    --match)
      if [[ $# -lt 2 ]]; then
        echo "missing value for --match" >&2
        exit 2
      fi
      match_keywords="$2"
      shift 2
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

# Shared awk helpers; YAML quoting q() comes from lib/yaml.sh.
awk_lib="$yaml_awk_lib"'
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function unquote(s,   f) {
  f = substr(s, 1, 1)
  if (length(s) >= 2 && (f == "\"" || f == "\047") && substr(s, length(s), 1) == f) return substr(s, 2, length(s) - 2)
  return s
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
!fence && /docs\/\.tasks\/[A-Za-z0-9]/ { tasklink = 1 }
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
  if (tasklink) print "W\t  - " q(path ": links to temporary task memory in docs/.tasks")
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
tracking="no-git"

index_docs() {
  local file status entry globs kind value line linkwarn

  while IFS= read -r file; do
    status=""
    entry=""
    globs=""
    linkwarn=""
    while IFS=$'\t' read -r kind value; do
      case "$kind" in
        S) status="$value" ;;
        C) globs+="$value"$'\n' ;;
        W) linkwarn="$value" ;;
        Y) entry+="$value"$'\n' ;;
      esac
    done < <(awk -v path="$file" "$awk_prog" "$file")

    if [[ "$include_all" -eq 0 && ( "$status" == superseded || "$status" == archived ) ]]; then
      skipped=$((skipped + 1))
      continue
    fi

    entries+="$entry"
    # Task memory is temporary; permanent docs must not point into it.
    [[ -z "$linkwarn" ]] || warnings+="$linkwarn"$'\n'
    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      glob_matches "${line%%$'\t'*}" || warnings+="  - ${line#*$'\t'}"$'\n'
    done <<< "$globs"
  done < <(find docs -type f -name '*.md' -not -path 'docs/_templates/*' -not -path '*/.*' | LC_ALL=C sort)
}

task_warning() {
  warnings+="  - $(yaml_quote "$1: $2")"$'\n'
}

# Emits "<SUMMARIES line count or -1><TAB><missing required headings>". Headings
# match case-insensitively. BOUNDARY lists the headings that end the SUMMARIES
# region: the Compass-required ones plus the project's own template headings, so
# sections an agent adds outside the template count toward it.
heading_prog='
BEGIN {
  n = split(ENVIRON["REQUIRED"], req, "\n")
  m = split(ENVIRON["BOUNDARY"], bnd, "\n")
  for (i = 1; i <= m; i++) if (bnd[i] != "") stop[tolower(bnd[i])] = 1
  count = -1
}
/^## / {
  line = $0; sub(/[ \t]+$/, "", line); line = tolower(line); seen[line] = 1
  if (line == "## summaries") { s = 1; count = 0; next }
  if (s && (line in stop)) s = 0
}
s { count++ }
END {
  missing = ""
  for (i = 1; i <= n; i++) {
    key = tolower(req[i])
    if (req[i] != "" && !(key in seen)) missing = missing (missing == "" ? "" : ", ") req[i]
  }
  print count "\t" missing
}
'

# Reads supporting file paths on stdin and prints a quoted YAML warning line for
# each one that goal.md or memories.md does not mention by name or top folder.
link_prog='
BEGIN {
  dir = ENVIRON["TASK_DIR"]
  while ((getline line < (dir "/goal.md")) > 0) text = text "\n" line
  while ((getline line < (dir "/memories.md")) > 0) text = text "\n" line
}
{
  rel = substr($0, length(dir) + 2)
  base = rel; sub(/.*\//, "", base)
  if (index(text, base)) next
  if (index(rel, "/")) { top = rel; sub(/\/.*/, "", top); if (index(text, top "/")) next }
  print "  - " q(dir ": supporting file not linked from goal.md or memories.md: " rel)
}
'

# Compass-required headings for a task file, from references/task-memory.xml.
core_for() {
  printf '%s\n' "$core_headings" | awk -F'\t' -v f="$1" '$1 == f { print $2 }'
}

index_tasks() {
  local name_re='^[0-9]{8}-[0-9]{4}_[A-Za-z0-9._-]+$'
  local references="$script_dir/../references/task-memory.xml"
  local dir status entry kind value missing file lines unlinked

  [[ -d docs/.tasks ]] || return 0

  # Task memory is committed by default; an ignored docs/.tasks must hold no
  # tracked files, and a committed one must not leave task folders untracked.
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git check-ignore -q --no-index docs/.tasks/; then
      tracking=ignored
      lines=$(( $(git ls-files -- docs/.tasks | wc -l) ))
      (( lines == 0 )) || task_warning "docs/.tasks" "tracked files although docs/.tasks is ignored: $lines"
    else
      tracking=committed
    fi
  fi

  if [[ ! -f "$references" ]]; then
    echo "Compass references not found: $references" >&2
    exit 1
  fi
  core_headings="$(awk -F'"' '/<heading file="/ { h = $0; sub(/.*">/, "", h); sub(/<\/heading>.*/, "", h); print $2 "\t" h }' "$references")"
  # Project template headings are not enforced; they only end the SUMMARIES region.
  summary_boundaries="$(
    core_for memories.md
    if [[ -f docs/_templates/task-memories.md ]]; then
      awk '/^## / { sub(/[ \t]+$/, ""); print }' docs/_templates/task-memories.md
    fi
  )"

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
        task_warning "$dir" "closed goal awaits close-out"
        ;;
    esac

    entries+="  - folder: $(yaml_quote "$dir")"$'\n'"$entry"

    if [[ "$tracking" == committed && -z "$(git ls-files -- "$dir" | head -n 1)" ]]; then
      task_warning "$dir" "not committed while docs/.tasks is committed"
    fi

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

    for file in goal.md diagram.md memories.md; do
      [[ -f "$dir/$file" ]] || continue
      IFS=$'\t' read -r lines missing < <(REQUIRED="$(core_for "$file")" BOUNDARY="$summary_boundaries" awk "$heading_prog" "$dir/$file")
      [[ -z "$missing" ]] || task_warning "$dir" "$file lacks required headings: $missing"
      if [[ "$file" == memories.md ]] && (( lines > summaries_line_limit )); then
        task_warning "$dir" "memories.md SUMMARIES has $lines lines (limit $summaries_line_limit)"
      fi
    done

    # Supporting files are read on demand, so goal.md or memories.md must link
    # them by file name or by their top folder. awk reads both files itself;
    # grep over bash here-strings crashed bash 3.2 (SIGBUS) on a real project.
    unlinked="$(find "$dir" -type f ! -name '.*' ! -path "$dir/goal.md" ! -path "$dir/diagram.md" ! -path "$dir/memories.md" \
      | LC_ALL=C sort | TASK_DIR="$dir" awk "$awk_lib$link_prog")"
    [[ -z "$unlinked" ]] || warnings+="$unlinked"$'\n'
  done < <(find docs/.tasks -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort)

  if [[ "$include_all" -eq 0 ]] && (( skipped > 0 )); then
    task_warning "docs/.tasks" "closed goals awaiting close-out: $skipped"
  fi
}

if [[ "$tasks_mode" -eq 1 ]]; then
  index_tasks
  list_key=tasks
else
  index_docs
  list_key=docs
fi

# --match narrows the index to entries containing at least one keyword
# (case-insensitive). Entries are split on their leading "  - " line, so path,
# type, summary, aliases, related, and code all take part in the match.
matched_count=""
if [[ -n "$match_keywords" ]]; then
  entries="$(printf '%s' "$entries" | MATCH_KW="$match_keywords" awk '
    function flush(   i, n, kws, kw, low) {
      if (buf == "") return
      low = tolower(buf)
      n = split(ENVIRON["MATCH_KW"], kws, ",")
      for (i = 1; i <= n; i++) {
        kw = kws[i]
        sub(/^[ \t]+/, "", kw)
        sub(/[ \t]+$/, "", kw)
        if (kw != "" && index(low, tolower(kw)) > 0) { out = out buf; return }
      }
    }
    /^  - / { flush(); buf = "" }
    { buf = buf $0 ORS }
    END { flush(); printf "%s", out }
  ')"
  # Command substitution strips trailing newlines; restore the one every entry
  # ends with so the following top-level keys stay on their own lines.
  [[ -z "$entries" ]] || entries+=$'\n'
  matched_count="$(printf '%s' "$entries" | grep -c '^  - ' || true)"
fi

printf '# Generated by Compass scripts/docs-index.sh. Do not store or edit.\n'
if [[ -n "$entries" ]]; then
  printf '%s:\n%s' "$list_key" "$entries"
else
  printf '%s: []\n' "$list_key"
fi
printf 'skipped: %d\n' "$skipped"
[[ "$tasks_mode" -eq 0 ]] || printf 'tracking: "%s"\n' "$tracking"
if [[ -n "$match_keywords" ]]; then
  printf 'match: %s\n' "$(yaml_quote "$match_keywords")"
  printf 'matched: %d\n' "$matched_count"
fi
if [[ -n "$warnings" ]]; then
  printf 'warnings:\n%s' "$warnings"
fi
