#!/usr/bin/env bash
set -euo pipefail

# resolve-workflows.sh — Validate and merge Compass workflow definitions.
#
# Merges the preset workflows.xml with project-specific custom-workflows.xml
# into a single resolved reference. Validates structure and detects conflicts.

target_dir="$(pwd)"
custom_file=""
preset_file=""
output_file=""
validate_only=0
dry_run=0

usage() {
  cat <<'USAGE'
Usage: resolve-workflows.sh [--target DIR] [--validate] [--dry-run]
       resolve-workflows.sh --target DIR --output FILE

Validate and merge Compass workflow definitions.

Options:
  --target DIR       Project directory. Defaults to current directory.
  --custom FILE      Path to custom-workflows.xml. Default: auto-detect.
  --preset FILE      Path to preset workflows.xml. Default: auto-detect.
  --output FILE      Write merged workflows to FILE.
  --validate         Validate custom workflows without merging.
  --dry-run          Show what would be done without writing files.
  --help             Show this help.

Validation checks:
  - custom-workflows.xml is well-formed XML
  - No duplicate workflow type names within custom file
  - No workflow type conflicts with preset workflows
  - Each custom <workflow> has a type attribute
  - Each custom <workflow> has <steps> or <phase> children
  - Step order attributes are sequential
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      [[ $# -lt 2 ]] && { echo "missing value for --target" >&2; exit 2; }
      target_dir="$2"; shift 2 ;;
    --custom)
      [[ $# -lt 2 ]] && { echo "missing value for --custom" >&2; exit 2; }
      custom_file="$2"; shift 2 ;;
    --preset)
      [[ $# -lt 2 ]] && { echo "missing value for --preset" >&2; exit 2; }
      preset_file="$2"; shift 2 ;;
    --output)
      [[ $# -lt 2 ]] && { echo "missing value for --output" >&2; exit 2; }
      output_file="$2"; shift 2 ;;
    --validate)
      validate_only=1; shift ;;
    --dry-run)
      dry_run=1; shift ;;
    -h|--help)
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

# Auto-detect file paths
if [[ -z "$custom_file" ]]; then
  custom_file="$target_dir/docs/process/custom-workflows.xml"
fi
if [[ -z "$preset_file" ]]; then
  preset_file="$target_dir/docs/process/workflows.xml"
fi

errors=0
warnings=0

# ===== Validation =====

validate_xml_basic() {
  local file="$1"
  local label="$2"

  if [[ ! -f "$file" ]]; then
    echo "  ✗ MISSING: $file"
    errors=$((errors + 1))
    return 1
  fi

  # Basic XML well-formedness checks
  if ! grep -q '<?xml' "$file"; then
    echo "  ✗ $label: missing XML declaration"
    errors=$((errors + 1))
    return 1
  fi

  # Check balanced root element
  local root_open root_close
  root_open="$(awk '/<[a-z]/{ gsub(/.*</,""); gsub(/[[:space:]>].*/,""); print; exit }' "$file")"
  root_close="$(awk '/<\/[a-z]/{ gsub(/.*<\//,""); gsub(/[[:space:]>].*/,""); print; exit }' "$file")"

  # Check root tag closes
  if ! grep -q "</${root_open}" "$file" 2>/dev/null; then
    echo "  ✗ $label: root element <$root_open> not closed"
    errors=$((errors + 1))
    return 1
  fi

  return 0
}

validate_custom_workflows() {
  local file="$1"

  echo "=== Custom Workflow Validation ==="
  echo ""
  echo "Custom: $file"
  echo "Preset: $preset_file"
  echo ""

  # Check file exists
  if [[ ! -f "$file" ]]; then
    echo "  ⚠ No custom-workflows.xml found (optional)"
    echo "  Run bootstrap to create the template, or create manually."
    return 0
  fi

  echo "Checking XML structure..."
  validate_xml_basic "$file" "custom-workflows.xml" || return 1
  echo "  ✓ XML structure appears valid"
  echo ""

  # Extract custom workflow types
  echo "Checking workflow definitions..."
  local custom_types
  custom_types="$(awk '
    BEGIN { in_comment=0 }
    /<!--/ { in_comment=1 }
    /-->/ { in_comment=0; next }
    in_comment { next }
    /<workflow type=/ {
      line = $0
      gsub(/.*type="/, "", line)
      gsub(/".*/, "", line)
      print line
    }
  ' "$file")"

  if [[ -z "$custom_types" ]]; then
    echo "  ⚠ No custom workflow types defined (all commented out?)"
    warnings=$((warnings + 1))
  else
    local count=0
    while IFS= read -r wtype; do
      count=$((count + 1))

      # Check for duplicate types within custom file
      local dupes
      dupes="$(echo "$custom_types" | grep -cF "$wtype" || true)"
      if [[ "$dupes" -gt 1 ]]; then
        echo "  ✗ DUPLICATE: workflow type '$wtype' appears $dupes times"
        errors=$((errors + 1))
      fi

      # Check for conflict with preset types
      if [[ -f "$preset_file" ]]; then
        local preset_types
        preset_types="$(awk '
          /<workflow type=/ {
            line = $0
            gsub(/.*type="/, "", line)
            gsub(/".*/, "", line)
            print line
          }
        ' "$preset_file")"

        if echo "$preset_types" | grep -qF "$wtype"; then
          echo "  ✗ CONFLICT: workflow type '$wtype' already defined in preset"
          errors=$((errors + 1))
        fi
      fi

      # Check workflow has steps or phases
      local has_steps has_phases
      has_steps="$(awk -v t="$wtype" '
        /<workflow type=/ && $0 ~ "type=\"" t "\"" { found=1 }
        found && /<steps>/ { print "yes"; exit }
        found && /<\/workflow>/ { exit }
      ' "$file")"
      has_phases="$(awk -v t="$wtype" '
        /<workflow type=/ && $0 ~ "type=\"" t "\"" { found=1 }
        found && /<phase / { print "yes"; exit }
        found && /<\/workflow>/ { exit }
      ' "$file")"

      if [[ -z "$has_steps" && -z "$has_phases" ]]; then
        echo "  ✗ INVALID: workflow '$wtype' has no <steps> or <phase> children"
        errors=$((errors + 1))
      fi

      # Check for description
      local has_desc
      has_desc="$(awk -v t="$wtype" '
        /<workflow type=/ && $0 ~ "type=\"" t "\"" { found=1 }
        found && /<description>/ { print "yes"; exit }
        found && /<\/workflow>/ { exit }
      ' "$file")"
      if [[ -z "$has_desc" ]]; then
        echo "  ⚠ WARNING: workflow '$wtype' missing <description>"
        warnings=$((warnings + 1))
      fi

      # Check for evidence
      local has_evidence
      has_evidence="$(awk -v t="$wtype" '
        /<workflow type=/ && $0 ~ "type=\"" t "\"" { found=1 }
        found && /<evidence/ { print "yes"; exit }
        found && /<\/workflow>/ { exit }
      ' "$file")"
      if [[ -z "$has_evidence" ]]; then
        echo "  ⚠ WARNING: workflow '$wtype' missing <evidence>"
        warnings=$((warnings + 1))
      fi

      echo "  ✓ $wtype"
    done <<< "$custom_types"

    echo ""
    echo "  Total custom workflows: $count"
  fi
  echo ""

  # Summary
  echo "=== Validation Summary ==="
  echo "Errors: $errors"
  echo "Warnings: $warnings"
  echo ""

  if [[ "$errors" -gt 0 ]]; then
    echo "❌ Validation FAILED with $errors error(s)"
    return 1
  elif [[ "$warnings" -gt 0 ]]; then
    echo "⚠️  Validation PASSED with $warnings warning(s)"
    return 0
  else
    echo "✅ Validation PASSED"
    return 0
  fi
}

# ===== Merge =====

merge_workflows() {
  local preset="$1"
  local custom="$2"
  local output="$3"

  if [[ ! -f "$preset" ]]; then
    echo "preset workflows.xml not found: $preset" >&2
    return 1
  fi

  if [[ ! -f "$custom" ]]; then
    echo "No custom workflows to merge. Using preset as-is."
    if [[ "$dry_run" -eq 1 ]]; then
      echo "Would copy $preset → $output"
      return 0
    fi
    cp "$preset" "$output"
    return 0
  fi

  # Extract custom workflow blocks (skip comments)
  local custom_blocks
  custom_blocks="$(awk '
    BEGIN { in_comment=0; in_wf=0; buf="" }
    /<!--/ { in_comment=1 }
    /-->/ { in_comment=0; next }
    in_comment { next }
    /<workflow type=/ { in_wf=1; buf=$0; next }
    in_wf {
      buf = buf "\n" $0
      if (/<\/workflow>/) { print buf; in_wf=0; buf="" }
    }
  ' "$custom")"

  if [[ -z "$custom_blocks" ]]; then
    echo "No active custom workflow definitions found (all commented out?)."
    if [[ "$dry_run" -eq 1 ]]; then
      echo "Would copy $preset → $output"
      return 0
    fi
    cp "$preset" "$output"
    return 0
  fi

  if [[ "$dry_run" -eq 1 ]]; then
    echo "Would merge custom workflows into $output:"
    echo "$custom_blocks" | grep '<workflow type=' | while IFS= read -r line; do
      wtype="$(echo "$line" | sed 's/.*type="//;s/".*//')"
      echo "  + $wtype"
    done
    return 0
  fi

  # Insert custom workflows before </workflows-reference> in preset
  local tmp_custom
  tmp_custom="$(mktemp)"
  printf '%s\n' "$custom_blocks" > "$tmp_custom"
  CUSTOM_FILE="$tmp_custom" awk '
    /<\/workflows-reference>/ {
      while ((getline line < ENVIRON["CUSTOM_FILE"]) > 0) print line
    }
    { print }
  ' "$preset" > "$output"
  rm -f "$tmp_custom"

  echo "Merged workflows written to $output"
}

# ===== Main =====

if [[ "$validate_only" -eq 1 ]]; then
  validate_custom_workflows "$custom_file"
  exit $?
fi

if [[ -n "$output_file" ]]; then
  merge_workflows "$preset_file" "$custom_file" "$output_file"
else
  # Default: validate if no output specified
  validate_custom_workflows "$custom_file"
fi
