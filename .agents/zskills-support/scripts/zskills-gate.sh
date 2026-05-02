#!/usr/bin/env bash
# Codex-native Z Skills gate checks. This script is intentionally read-only:
# it reports missing evidence before landing, pushing, or continuing chunks.

set -u

MODE="pre-land"
REPO="."
PIPELINE_ID=""
TRACKING_ID=""
PLAN_SLUG=""
PLAN_FILE=""
REPORT_PATH=""
BASE_REF=""

usage() {
  cat >&2 <<'EOF'
Usage: zskills-gate.sh [options]
  --mode <pre-land|post-land|pre-push|pre-continue>
  --repo <path>
  --pipeline <id>
  --tracking-id <id>
  --plan-slug <slug>
  --plan-file <path>
  --report <path>
  --base-ref <ref>
EOF
}

fail() {
  echo "GATE-FAIL: $*" >&2
  FAILED=1
}

warn() {
  echo "GATE-WARN: $*" >&2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --pipeline) PIPELINE_ID="$2"; shift 2 ;;
    --tracking-id) TRACKING_ID="$2"; shift 2 ;;
    --plan-slug) PLAN_SLUG="$2"; shift 2 ;;
    --plan-file) PLAN_FILE="$2"; shift 2 ;;
    --report) REPORT_PATH="$2"; shift 2 ;;
    --base-ref) BASE_REF="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown arg '$1'" >&2; usage; exit 2 ;;
  esac
done

case "$MODE" in
  pre-land|post-land|pre-push|pre-continue) ;;
  *) echo "ERROR: unsupported mode '$MODE'" >&2; exit 2 ;;
esac

FAILED=0

if ! git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: repo is not a git worktree: $REPO" >&2
  exit 2
fi

ROOT=$(git -C "$REPO" rev-parse --show-toplevel)
TRACKING_ROOT="$ROOT/.zskills/tracking"

if [ -d "$ROOT/.zskills" ]; then
  if ! git -C "$ROOT" check-ignore -q "$ROOT/.zskills/tracking" 2>/dev/null; then
    fail ".zskills/tracking/ exists but is not ignored by git"
  fi
fi

if [ -n "$PIPELINE_ID" ]; then
  PIPELINE_DIR="$TRACKING_ROOT/$PIPELINE_ID"
  [ -d "$PIPELINE_DIR" ] || fail "tracking pipeline directory missing: $PIPELINE_DIR"
else
  PIPELINE_DIR=""
fi

if [ -n "$TRACKING_ID" ] && [ -n "$PIPELINE_DIR" ] && [ -d "$PIPELINE_DIR" ]; then
  case "$PIPELINE_ID" in
    fix-issues.*)
      [ -e "$PIPELINE_DIR/pipeline.fix-issues.$TRACKING_ID" ] || fail "missing marker: pipeline.fix-issues.$TRACKING_ID"
      for suffix in preflight prioritize execute verify report; do
        [ -e "$PIPELINE_DIR/step.fix-issues.$TRACKING_ID.$suffix" ] || fail "missing marker: step.fix-issues.$TRACKING_ID.$suffix"
      done
      if [ "$MODE" = "pre-land" ] || [ "$MODE" = "pre-push" ]; then
        [ -e "$PIPELINE_DIR/step.fix-issues.$TRACKING_ID.land" ] || fail "missing marker: step.fix-issues.$TRACKING_ID.land"
        compgen -G "$PIPELINE_DIR/issue.*.selected" >/dev/null || fail "no per-issue selected markers found"
        compgen -G "$PIPELINE_DIR/issue.*.verified" >/dev/null || fail "no per-issue verified markers found"
      fi
      ;;
    *)
      for suffix in implement verify report; do
        [ -e "$PIPELINE_DIR/step.run-plan.$TRACKING_ID.$suffix" ] || fail "missing marker: step.run-plan.$TRACKING_ID.$suffix"
      done
      if [ "$MODE" = "pre-continue" ]; then
        [ -e "$PIPELINE_DIR/handoff.run-plan.$TRACKING_ID" ] || fail "handoff marker missing: handoff.run-plan.$TRACKING_ID"
      fi
      if [ "$MODE" = "post-land" ]; then
        [ -e "$PIPELINE_DIR/step.run-plan.$TRACKING_ID.land" ] || fail "missing marker: step.run-plan.$TRACKING_ID.land"
        [ -e "$PIPELINE_DIR/fulfilled.run-plan.$TRACKING_ID" ] || fail "missing marker: fulfilled.run-plan.$TRACKING_ID"
      fi
      ;;
  esac

  if [ "$MODE" = "pre-land" ] || [ "$MODE" = "pre-push" ]; then
    [ -e "$PIPELINE_DIR/requires.verify-changes.$TRACKING_ID" ] || fail "verifier requirement marker missing: requires.verify-changes.$TRACKING_ID"
    [ -e "$PIPELINE_DIR/step.verify-changes.$TRACKING_ID.complete" ] || fail "verifier complete marker missing: step.verify-changes.$TRACKING_ID.complete"
    [ -e "$PIPELINE_DIR/fulfilled.verify-changes.$TRACKING_ID" ] || fail "verifier fulfilled marker missing: fulfilled.verify-changes.$TRACKING_ID"
  fi
fi

if [ -z "$REPORT_PATH" ] && [ -n "$PLAN_SLUG" ]; then
  REPORT_PATH="$ROOT/reports/plan-$PLAN_SLUG.md"
fi
if [ -n "$REPORT_PATH" ] && [ ! -f "$REPORT_PATH" ]; then
  fail "report missing: $REPORT_PATH"
fi

if [ -n "$PLAN_FILE" ] && [ ! -f "$PLAN_FILE" ]; then
  fail "plan file missing: $PLAN_FILE"
fi

if [ -n "$BASE_REF" ]; then
  if git -C "$ROOT" rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
    true
  else
    warn "base ref not available for freshness check: $BASE_REF"
  fi
fi

STATUS=$(git -C "$ROOT" status --short --untracked-files=all)
if [ -n "$STATUS" ]; then
  while IFS= read -r line; do
    path=${line#???}
    case "$path" in
      .zskills/*|.zskills-tracked) ;;
      *) fail "uncommitted or untracked project artifact remains: $line" ;;
    esac
  done <<EOF
$STATUS
EOF
fi

if [ "$FAILED" -ne 0 ]; then
  echo "Z Skills gate failed for mode '$MODE'." >&2
  exit 1
fi

echo "Z Skills gate passed for mode '$MODE'."
