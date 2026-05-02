#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

OUT_DIR="zskills-online-variant-report-canary"
MANIFEST="$OUT_DIR/manifest.txt"
FINAL_REPORT="reports/zskills-variant-research-report.md"

EXPECTED=(
  "phase-1-source-ledger.md"
  "phase-2-current-evidence.md"
  "phase-3-comparative-analysis.md"
  "phase-4-dev-implications.md"
  "phase-5-report-quality.md"
)

die() {
  echo "error: $*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || die "missing required file: $1"
}

require_contains() {
  local file="$1"
  local needle="$2"
  grep -Fq "$needle" "$file" || die "$file missing required text: $needle"
}

require_regex() {
  local file="$1"
  local pattern="$2"
  grep -Eq "$pattern" "$file" || die "$file missing required pattern: $pattern"
}

require_manifest_entry() {
  local entry="$1"
  local expected_index="$2"
  [[ "$entry" == "${EXPECTED[$expected_index]}" ]] || die "manifest entry $entry is out of order or unknown"
}

require_phase_1() {
  local file="$OUT_DIR/phase-1-source-ledger.md"
  require_file "$file"
  require_contains "$file" "# Phase 1 Source Ledger"
  require_contains "$file" "## Research Date"
  require_contains "$file" "## Target Repositories"
  require_contains "$file" "## Required Evidence Types"
  require_contains "$file" "## Citation Rules"
  require_contains "$file" "## Evidence Gaps"
  require_contains "$file" "https://github.com/zeveck/zskills"
  require_contains "$file" "https://github.com/zeveck/zskills-dev"
  require_contains "$file" "https://github.com/zeveck/zskills-cc"
  require_contains "$file" "https://github.com/zeveck/zskills-codex"
  require_contains "$file" "every material claim in the final report must be traceable"
  require_contains "$file" "zskills-codex means this local implementation"
  require_contains "$file" "publication target"
}

require_phase_2() {
  local file="$OUT_DIR/phase-2-current-evidence.md"
  require_file "$file"
  require_contains "$file" "# Phase 2 Current Evidence"
  for heading in "## zskills" "## zskills-dev" "## zskills-cc" "## zskills-codex Implementation" "## zskills-codex Publication Target" "## Evidence Gaps and Access Limits"; do
    require_contains "$file" "$heading"
  done
  for term in GitHub README commit branch tags skills config hooks tests reports; do
    require_contains "$file" "$term"
  done
  for url in "https://github.com/zeveck/zskills" "https://github.com/zeveck/zskills-dev" "https://github.com/zeveck/zskills-cc" "https://github.com/zeveck/zskills-codex"; do
    require_contains "$file" "$url"
  done
  require_contains "$file" "| repository | observed purpose | default branch | visible commit count or revision evidence | key directories/files | install/config model | tests or validation | evidence URL |"
  local github_count
  github_count="$(grep -o 'https://github.com/zeveck/[^ )|]*' "$file" | wc -l)"
  [[ "$github_count" -ge 10 ]] || die "$file has fewer than ten GitHub source URLs"
  local local_path_count
  local_path_count="$(grep -Eo '(^|[ `|])([A-Za-z0-9_.-]+/)+[A-Za-z0-9_.-]*|(^|[ `|])[A-Za-z0-9_.-]+\\.md' "$file" | wc -l)"
  [[ "$local_path_count" -ge 3 ]] || die "$file has fewer than three local source paths"
  require_contains "$file" "refreshed if GitHub changes after the research date"
}

require_phase_3() {
  local file="$OUT_DIR/phase-3-comparative-analysis.md"
  require_file "$file"
  require_contains "$file" "# Phase 3 Comparative Analysis"
  for heading in "## Executive Comparison" "## Repository Roles" "## Runtime and Client Model" "## Installation and Configuration" "## Support Assets and Automation" "## Testing and Release Posture" "## Risks and Open Questions"; do
    require_contains "$file" "$heading"
  done
  for name in zskills zskills-dev zskills-cc zskills-codex; do
    require_contains "$file" "$name"
  done
  local matrix_rows
  matrix_rows="$(grep -Ec '^\\|[^|]+\\|[^|]+\\|' "$file")"
  [[ "$matrix_rows" -ge 12 ]] || die "$file comparison matrix has fewer than ten data rows plus header"
  for phrase in "public release" "development source" "cross-client compatibility conversion" "GitHub publication target" "Claude-specific" "Codex-specific" "dual-client" "unknown"; do
    require_contains "$file" "$phrase"
  done
}

require_phase_4() {
  local file="$OUT_DIR/phase-4-dev-implications.md"
  require_file "$file"
  require_contains "$file" "# Phase 4 Dev Implications"
  for heading in "## zskills-dev Change Surfaces" "## Application Strategy for zskills-cc" "## Application Strategy for zskills-codex" "## Direct Import vs Adapt vs Reject vs Defer" "## Verification Strategy" "## Release Recommendations"; do
    require_contains "$file" "$heading"
  done
  for term in zskills-dev zskills-cc zskills-codex zskills frontmatter hooks runner tracking installer "config schema" tests reports release migration; do
    require_contains "$file" "$term"
  done
  local table_rows
  table_rows="$(grep -Ec '^\\|[^|]+\\|[^|]+\\|' "$file")"
  [[ "$table_rows" -ge 14 ]] || die "$file tables do not contain enough rows"
  for phrase in "import directly" "adapt behind a client boundary" "adapt to Codex-native behavior" "reject" "defer" "stale GitHub evidence" "publication state" "runtime assumptions" "generated output drift" "release timing"; do
    require_contains "$file" "$phrase"
  done
}

require_phase_5() {
  local file="$OUT_DIR/phase-5-report-quality.md"
  require_file "$file"
  require_contains "$file" "# Phase 5 Report Quality"
  for heading in "## Final Report Path" "## Quality Checks" "## Verification Commands" "## Canary Result"; do
    require_contains "$file" "$heading"
  done
  require_contains "$file" "ready for maintainer review"
  for term in citations "evidence labels" "comparison matrix" "dev implications" recommendations risks "open questions"; do
    require_contains "$file" "$term"
  done
}

require_final_report() {
  require_file "$FINAL_REPORT"
  for heading in "# ZSkills Variant Research Report" "## Executive Summary" "## Research Scope and Method" "## Source Inventory" "## Repository-by-Repository Findings" "## Comparative Matrix" "## zskills-dev Implications" "## Recommendations" "## Evidence Gaps and Risks" "## Appendix: Sources"; do
    require_contains "$FINAL_REPORT" "$heading"
  done
  for name in zskills zskills-dev zskills-cc zskills-codex; do
    require_contains "$FINAL_REPORT" "$name"
  done
  for url in "https://github.com/zeveck/zskills" "https://github.com/zeveck/zskills-dev" "https://github.com/zeveck/zskills-cc" "https://github.com/zeveck/zskills-codex"; do
    require_contains "$FINAL_REPORT" "$url"
  done
  for term in "2026-05-02" "GitHub evidence may change" Observed Inferred Unknown "zskills-cc" "zskills-codex" "populated" "empty"; do
    require_contains "$FINAL_REPORT" "$term"
  done
  require_regex "$FINAL_REPORT" 'Canary Result|canary result'
}

require_file "$MANIFEST"
mapfile -t manifest_entries < "$MANIFEST"
[[ "${#manifest_entries[@]}" -ge 1 ]] || die "manifest must contain at least one phase file"
[[ "${#manifest_entries[@]}" -le "${#EXPECTED[@]}" ]] || die "manifest contains too many entries"

for i in "${!manifest_entries[@]}"; do
  require_manifest_entry "${manifest_entries[$i]}" "$i"
  require_file "$OUT_DIR/${manifest_entries[$i]}"
done

for i in "${!manifest_entries[@]}"; do
  case "$i" in
    0) require_phase_1 ;;
    1) require_phase_2 ;;
    2) require_phase_3 ;;
    3) require_phase_4 ;;
    4) require_phase_5 ;;
    *) die "unknown phase index $i" ;;
  esac
done

if [[ "${#manifest_entries[@]}" -eq 5 ]]; then
  require_final_report
  while IFS= read -r file; do
    case "$file" in
      manifest.txt|phase-1-source-ledger.md|phase-2-current-evidence.md|phase-3-comparative-analysis.md|phase-4-dev-implications.md|phase-5-report-quality.md) ;;
      *) die "unexpected top-level output file: $OUT_DIR/$file" ;;
    esac
  done < <(find "$OUT_DIR" -maxdepth 1 -type f -printf '%f\n')
else
  [[ ! -e "$FINAL_REPORT" ]] || die "$FINAL_REPORT should not exist before phase 5"
fi

echo "zskills online variant report canary checks passed for ${#manifest_entries[@]} phase(s)."
