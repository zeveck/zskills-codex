#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root"

output_dir="zskills-variant-review-canary"
manifest="$output_dir/manifest.txt"

if [[ ! -f "$manifest" ]]; then
  echo "Missing $manifest" >&2
  exit 1
fi

mapfile -t entries < "$manifest"

expected=(
  "phase-1-inventory.md"
  "phase-2-variant-comparison.md"
  "phase-3-adoption-surfaces.md"
  "phase-4-dev-change-application-plan.md"
  "phase-5-overview.md"
)

if (( ${#entries[@]} < 1 || ${#entries[@]} > ${#expected[@]} )); then
  echo "Manifest must contain 1-${#expected[@]} entries" >&2
  exit 1
fi

for i in "${!entries[@]}"; do
  if [[ "${entries[$i]}" != "${expected[$i]}" ]]; then
    echo "Unexpected or out-of-order manifest entry at line $((i + 1)): ${entries[$i]}" >&2
    exit 1
  fi
done

require_contains() {
  local file="$1"
  local needle="$2"

  if ! grep -Fq "$needle" "$file"; then
    echo "Missing required text in $file: $needle" >&2
    exit 1
  fi
}

check_file_exists() {
  local entry="$1"
  local path="$output_dir/$entry"

  if [[ ! -f "$path" ]]; then
    echo "Missing $path" >&2
    exit 1
  fi
}

check_phase_1() {
  local file="$output_dir/phase-1-inventory.md"
  require_contains "$file" "# Phase 1 Inventory"
  require_contains "$file" "## Local Evidence Reviewed"
  require_contains "$file" "## Variant Names"
  require_contains "$file" "## Evidence Gaps"
  require_contains "$file" "## Initial Observations"
  require_contains "$file" "zskills"
  require_contains "$file" "zskills-cc"
  require_contains "$file" "zskills-codex"
  require_contains "$file" "zskills-dev"
  require_contains "$file" "README.md"
  require_contains "$file" "skills/"
  require_contains "$file" "zskills-support/"
  require_contains "$file" "plans/"
  require_contains "$file" "reports/"
  require_contains "$file" "missing local evidence must be treated as an evidence gap"
}

check_phase_2() {
  local file="$output_dir/phase-2-variant-comparison.md"
  require_contains "$file" "# Phase 2 Variant Comparison"
  require_contains "$file" "## Comparison Matrix"
  require_contains "$file" "## Runtime Assumptions"
  require_contains "$file" "## Porting Differences"
  require_contains "$file" "## Evidence Gaps"
  require_contains "$file" "zskills"
  require_contains "$file" "zskills-cc"
  require_contains "$file" "zskills-codex"
  require_contains "$file" "zskills-dev"
  require_contains "$file" "| Variant |"
  require_contains "$file" "runtime host"
  require_contains "$file" "instruction format"
  require_contains "$file" "support assets"
  require_contains "$file" "tracking model"
  require_contains "$file" "landing model"
  require_contains "$file" "integration risk"
  require_contains "$file" "observed local evidence"
  require_contains "$file" "inference"
}

check_phase_3() {
  local file="$output_dir/phase-3-adoption-surfaces.md"
  require_contains "$file" "# Phase 3 Adoption Surfaces"
  require_contains "$file" "## zskills-codex Surfaces"
  require_contains "$file" "## zskills-cc Surfaces"
  require_contains "$file" "## Shared Surfaces"
  require_contains "$file" "## Divergence Risks"
  require_contains "$file" "skills/"
  require_contains "$file" "zskills-support/"
  require_contains "$file" "runner"
  require_contains "$file" "tracking"
  require_contains "$file" "hooks"
  require_contains "$file" "installer"
  require_contains "$file" "configuration"
  require_contains "$file" "Codex-native behavior"
  require_contains "$file" "Claude-only runtime assumptions"
}

check_phase_4() {
  local file="$output_dir/phase-4-dev-change-application-plan.md"
  require_contains "$file" "# Phase 4 Dev Change Application Plan"
  require_contains "$file" "## Intake Checklist"
  require_contains "$file" "## Change Classification"
  require_contains "$file" "## Application Strategy for zskills-cc"
  require_contains "$file" "## Application Strategy for zskills-codex"
  require_contains "$file" "## Compatibility Gates"
  require_contains "$file" "## Verification Matrix"
  require_contains "$file" "## Release Readiness"
  require_contains "$file" "zskills-dev"
  require_contains "$file" "zskills-cc"
  require_contains "$file" "zskills-codex"
  require_contains "$file" "frontmatter"
  require_contains "$file" "support scripts"
  require_contains "$file" "hooks"
  require_contains "$file" "runner"
  require_contains "$file" "tracking markers"
  require_contains "$file" "config schema"
  require_contains "$file" "tests"
  require_contains "$file" "reports"
  require_contains "$file" "skill text"
  require_contains "$file" "installer"
  require_contains "$file" "runtime policy"
  require_contains "$file" "cross-runtime assumptions"
  require_contains "$file" "marker compatibility"
  require_contains "$file" "stale reports"
  require_contains "$file" "upstream drift"
  require_contains "$file" "refreshed against the actual zskills-dev diff"
}

check_phase_5() {
  local file="$output_dir/phase-5-overview.md"
  require_contains "$file" "# Phase 5 Overview"
  require_contains "$file" "## Executive Summary"
  require_contains "$file" "## What We Know"
  require_contains "$file" "## What Needs Fresh Diff Review"
  require_contains "$file" "## Recommended Next Steps"
  require_contains "$file" "## Canary Result"
  require_contains "$file" "zskills"
  require_contains "$file" "zskills-cc"
  require_contains "$file" "zskills-codex"
  require_contains "$file" "zskills-dev"
  require_contains "$file" "ready for fresh zskills-dev diff review"
}

for entry in "${entries[@]}"; do
  check_file_exists "$entry"
  case "$entry" in
    phase-1-inventory.md) check_phase_1 ;;
    phase-2-variant-comparison.md) check_phase_2 ;;
    phase-3-adoption-surfaces.md) check_phase_3 ;;
    phase-4-dev-change-application-plan.md) check_phase_4 ;;
    phase-5-overview.md) check_phase_5 ;;
    *)
      echo "Unknown manifest entry: $entry" >&2
      exit 1
      ;;
  esac
done

if (( ${#entries[@]} == ${#expected[@]} )); then
  mapfile -t actual_files < <(find "$output_dir" -maxdepth 1 -type f -printf '%f\n' | sort)
  expected_files=("manifest.txt" "${expected[@]}")
  mapfile -t sorted_expected < <(printf '%s\n' "${expected_files[@]}" | sort)

  if [[ "${actual_files[*]}" != "${sorted_expected[*]}" ]]; then
    echo "Unexpected top-level files in $output_dir" >&2
    printf 'Actual:\n%s\n' "${actual_files[*]}" >&2
    printf 'Expected:\n%s\n' "${sorted_expected[*]}" >&2
    exit 1
  fi
fi
