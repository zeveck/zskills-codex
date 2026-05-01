#!/usr/bin/env bash
set -eu

if [ "${1:-}" = "--version" ]; then
  echo "fake-codex 1.0"
  exit 0
fi

if [ "${1:-}" != "exec" ]; then
  echo "fake-codex: expected exec" >&2
  exit 2
fi

LAST_MESSAGE=""
REPO=""
MODE="${FAKE_CODEX_MODE:-success}"
while [ $# -gt 0 ]; do
  case "$1" in
    -C)
      REPO="$2"
      shift 2
      ;;
    -o|--output-last-message)
      LAST_MESSAGE="$2"
      shift 2
      ;;
    *) shift ;;
  esac
done

write_progress() {
  local with_handoff="$1"
  local report_mode="${2:-normal}"
  local marker_mode="${3:-normal}"
  local dirty_mode="${4:-clean}"
  local complete_mode="${5:-incomplete}"
  [ -n "$REPO" ] || { echo "fake-codex: missing -C repo" >&2; exit 2; }
  mkdir -p "$REPO/reports" "$REPO/.zskills/tracking/run-plan.example"
  if [ "$report_mode" = "normal" ]; then
    cat > "$REPO/reports/plan-example.md" <<'MD'
# Example Plan Report

## Phase 1: Fixture Progress

Status: verified.

Scope Assessment:

- Fixture-only progress for runner validation.

Verification:

- fake verifier passed.
MD
    git -C "$REPO" add reports/plan-example.md
    git -C "$REPO" commit -q -m "fixture progress"
  elif [ "$report_mode" = "no-scope" ]; then
    cat > "$REPO/reports/plan-example.md" <<'MD'
# Example Plan Report

## Phase 1: Fixture Progress

Status: verified.

Verification:

- fake verifier passed.
MD
    git -C "$REPO" add reports/plan-example.md
    git -C "$REPO" commit -q -m "fixture progress"
  fi
  local tracking="$REPO/.zskills/tracking/run-plan.example"
  if [ "$complete_mode" = "complete" ]; then
    python3 - "$REPO/plans/example.md" <<'PY'
import re
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text = re.sub(r"⬜ Not Started", "✅ Done", text, count=1)
open(path, "w", encoding="utf-8").write(text)
PY
    git -C "$REPO" add plans/example.md
    git -C "$REPO" commit -q -m "fixture plan complete"
  fi
  printf 'implemented\n' > "$tracking/step.run-plan.example.phase-1.implement"
  printf 'verified\n' > "$tracking/step.run-plan.example.phase-1.verify"
  printf 'reported\n' > "$tracking/step.run-plan.example.phase-1.report"
  if [ "$complete_mode" = "complete" ] || [ "$complete_mode" = "premature-final" ]; then
    printf 'landed\n' > "$tracking/step.run-plan.example.phase-1.land"
  fi
  if [ "$marker_mode" = "normal" ]; then
    printf 'required\n' > "$tracking/requires.verify-changes.example.phase-1"
    printf 'complete\n' > "$tracking/step.verify-changes.example.phase-1.complete"
    printf 'fulfilled\n' > "$tracking/fulfilled.verify-changes.example.phase-1"
  fi
  if [ "$complete_mode" = "complete" ] || [ "$complete_mode" = "premature-final" ]; then
    printf 'fulfilled\n' > "$tracking/fulfilled.run-plan.example.phase-1"
  fi
  if [ "$with_handoff" = "yes" ]; then
    printf 'handoff\n' > "$tracking/handoff.run-plan.example.phase-1"
  fi
  if [ "$dirty_mode" = "dirty" ]; then
    printf 'dirty\n' > "$REPO/dirty-artifact.txt"
  fi
}

write_multi_progress() {
  [ -n "$REPO" ] || { echo "fake-codex: missing -C repo" >&2; exit 2; }
  mkdir -p "$REPO/reports" "$REPO/.zskills/tracking/run-plan.example"
  local phase
  phase=$(python3 - "$REPO/plans/example.md" <<'PY'
import re
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
for match in re.finditer(r"^\| ([0-9]+)\. .*? \| ⬜ Not Started \|", text, flags=re.M):
    print(match.group(1))
    break
else:
    print("")
PY
)
  [ -n "$phase" ] || { echo "fake-codex: multi plan already complete" >&2; exit 0; }
  python3 - "$REPO/plans/example.md" "$phase" <<'PY'
import re
import sys
path, phase = sys.argv[1:3]
text = open(path, encoding="utf-8").read()
pattern = rf"^(\| {re.escape(phase)}\. .*? \| )⬜ Not Started( \|)"
text = re.sub(pattern, rf"\1✅ Done\2", text, count=1, flags=re.M)
open(path, "w", encoding="utf-8").write(text)
PY
  {
    printf '# Example Plan Report\n\n'
    for n in $(seq 1 "$phase"); do
      printf '## Phase %s: Fixture Progress\n\n' "$n"
      printf 'Status: verified.\n\n'
      printf 'Scope Assessment:\n\n'
      printf -- '- Fixture-only multi-chunk progress for runner validation.\n\n'
      printf 'Verification:\n\n'
      printf -- '- fake verifier passed.\n\n'
    done
  } > "$REPO/reports/plan-example.md"
  local tracking="$REPO/.zskills/tracking/run-plan.example"
  local remaining="no"
  if grep -q '⬜ Not Started' "$REPO/plans/example.md"; then
    remaining="yes"
  fi
  printf 'implemented\n' > "$tracking/step.run-plan.example.phase-$phase.implement"
  printf 'verified\n' > "$tracking/step.run-plan.example.phase-$phase.verify"
  printf 'reported\n' > "$tracking/step.run-plan.example.phase-$phase.report"
  printf 'required\n' > "$tracking/requires.verify-changes.example.phase-$phase"
  printf 'complete\n' > "$tracking/step.verify-changes.example.phase-$phase.complete"
  printf 'fulfilled\n' > "$tracking/fulfilled.verify-changes.example.phase-$phase"
  if [ "$remaining" = "yes" ]; then
    printf 'handoff\n' > "$tracking/handoff.run-plan.example.phase-$phase"
  else
    printf 'landed\n' > "$tracking/step.run-plan.example.phase-$phase.land"
    printf 'fulfilled\n' > "$tracking/fulfilled.run-plan.example.phase-$phase"
  fi
  git -C "$REPO" add plans/example.md reports/plan-example.md
  git -C "$REPO" commit -q -m "fixture phase $phase progress"
}

write_reused_handoff_progress() {
  [ -n "$REPO" ] || { echo "fake-codex: missing -C repo" >&2; exit 2; }
  mkdir -p "$REPO/reports" "$REPO/.zskills/tracking/run-plan.example"
  local tracking_id="example.phase-1"
  local tracking="$REPO/.zskills/tracking/run-plan.example"
  local phase
  phase=$(python3 - "$REPO/plans/example.md" <<'PY'
import re
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
for match in re.finditer(r"^\| ([0-9]+)\. .*? \| ⬜ Not Started \|", text, flags=re.M):
    print(match.group(1))
    break
else:
    print("")
PY
)
  [ -n "$phase" ] || { echo "fake-codex: reused handoff plan already complete" >&2; exit 0; }
  python3 - "$REPO/plans/example.md" "$phase" <<'PY'
import re
import sys
path, phase = sys.argv[1:3]
text = open(path, encoding="utf-8").read()
pattern = rf"^(\| {re.escape(phase)}\. .*? \| )⬜ Not Started( \|)"
text = re.sub(pattern, rf"\1✅ Done\2", text, count=1, flags=re.M)
open(path, "w", encoding="utf-8").write(text)
PY
  {
    printf '# Example Plan Report\n\n'
    printf '## Phase %s: Fixture Progress\n\n' "$phase"
    printf 'Status: verified.\n\n'
    printf 'Scope Assessment:\n\n'
    printf -- '- Fixture-only reused handoff progress for runner validation.\n\n'
    printf 'Verification:\n\n'
    printf -- '- fake verifier passed.\n\n'
  } > "$REPO/reports/plan-example.md"
  printf 'implemented phase %s\n' "$phase" > "$tracking/step.run-plan.$tracking_id.implement"
  printf 'verified phase %s\n' "$phase" > "$tracking/step.run-plan.$tracking_id.verify"
  printf 'reported phase %s\n' "$phase" > "$tracking/step.run-plan.$tracking_id.report"
  printf 'required phase %s\n' "$phase" > "$tracking/requires.verify-changes.$tracking_id"
  printf 'complete phase %s\n' "$phase" > "$tracking/step.verify-changes.$tracking_id.complete"
  printf 'fulfilled phase %s\n' "$phase" > "$tracking/fulfilled.verify-changes.$tracking_id"
  printf 'handoff phase %s\n' "$phase" > "$tracking/handoff.run-plan.$tracking_id"
  git -C "$REPO" add plans/example.md reports/plan-example.md
  git -C "$REPO" commit -q -m "fixture reused handoff phase $phase progress"
}

case "$MODE" in
  success)
    echo '{"event":"fake","message":"ok"}'
    [ -z "$LAST_MESSAGE" ] || printf 'fake success\n' > "$LAST_MESSAGE"
    exit 0
    ;;
  fail)
    echo '{"event":"fake","message":"fail"}'
    [ -z "$LAST_MESSAGE" ] || printf 'fake fail\n' > "$LAST_MESSAGE"
    exit 7
    ;;
  sleep)
    sleep "${FAKE_CODEX_SLEEP_SECONDS:-5}"
    [ -z "$LAST_MESSAGE" ] || printf 'fake sleep\n' > "$LAST_MESSAGE"
    exit 0
    ;;
  idle)
    echo '{"event":"fake","message":"before idle"}'
    sleep "${FAKE_CODEX_SLEEP_SECONDS:-5}"
    [ -z "$LAST_MESSAGE" ] || printf 'fake idle\n' > "$LAST_MESSAGE"
    exit 0
    ;;
  progress)
    write_progress yes normal normal clean complete
    echo '{"event":"fake","message":"progress"}'
    [ -z "$LAST_MESSAGE" ] || printf 'fake progress\n' > "$LAST_MESSAGE"
    exit 0
    ;;
  progress-no-handoff)
    write_progress no
    echo '{"event":"fake","message":"progress without handoff"}'
    [ -z "$LAST_MESSAGE" ] || printf 'fake progress without handoff\n' > "$LAST_MESSAGE"
    exit 0
    ;;
  progress-missing-report)
    write_progress yes missing
    echo '{"event":"fake","message":"progress missing report"}'
    [ -z "$LAST_MESSAGE" ] || printf 'fake progress missing report\n' > "$LAST_MESSAGE"
    exit 0
    ;;
  progress-no-scope)
    write_progress yes no-scope
    echo '{"event":"fake","message":"progress no scope"}'
    [ -z "$LAST_MESSAGE" ] || printf 'fake progress no scope\n' > "$LAST_MESSAGE"
    exit 0
    ;;
  progress-missing-verifier)
    write_progress yes normal missing-verifier
    echo '{"event":"fake","message":"progress missing verifier"}'
    [ -z "$LAST_MESSAGE" ] || printf 'fake progress missing verifier\n' > "$LAST_MESSAGE"
    exit 0
    ;;
  progress-dirty)
    write_progress yes normal normal dirty
    echo '{"event":"fake","message":"progress dirty"}'
    [ -z "$LAST_MESSAGE" ] || printf 'fake progress dirty\n' > "$LAST_MESSAGE"
    exit 0
    ;;
  progress-premature-final)
    write_progress yes normal normal clean premature-final
    echo '{"event":"fake","message":"progress premature final"}'
    [ -z "$LAST_MESSAGE" ] || printf 'fake progress premature final\n' > "$LAST_MESSAGE"
    exit 0
    ;;
  multi-progress)
    write_multi_progress
    echo '{"event":"fake","message":"multi progress"}'
    [ -z "$LAST_MESSAGE" ] || printf 'fake multi progress\n' > "$LAST_MESSAGE"
    exit 0
    ;;
  reuse-handoff-progress)
    write_reused_handoff_progress
    echo '{"event":"fake","message":"reuse handoff progress"}'
    [ -z "$LAST_MESSAGE" ] || printf 'fake reuse handoff progress\n' > "$LAST_MESSAGE"
    exit 0
    ;;
  no-progress)
    echo '{"event":"fake","message":"no progress"}'
    [ -z "$LAST_MESSAGE" ] || printf 'fake no progress\n' > "$LAST_MESSAGE"
    exit 0
    ;;
  *)
    echo "fake-codex: unknown FAKE_CODEX_MODE=$MODE" >&2
    exit 2
    ;;
esac
