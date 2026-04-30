#!/usr/bin/env bash
set -eu

TEST_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SUPPORT_DIR=$(cd "$TEST_DIR/../.." && pwd)
SCRIPT="$SUPPORT_DIR/scripts/zskills-runner.sh"
FAKE_CODEX="$TEST_DIR/fake-codex.sh"
CASE="${1:-all}"

tmpdir=""
cleanup() {
  [ -z "$tmpdir" ] || rm -rf "$tmpdir"
}
trap cleanup EXIT

make_repo() {
  tmpdir=$(mktemp -d)
  git -C "$tmpdir" init -q
  git -C "$tmpdir" config user.email runner@example.test
  git -C "$tmpdir" config user.name "Runner Test"
  mkdir -p "$tmpdir/plans" "$tmpdir/.codex"
  cat > "$tmpdir/plans/example.md" <<'MD'
# Example Plan

## Progress Tracker

| Phase | Status | Notes |
| --- | --- | --- |
| 1. Fixture Phase | ⬜ Not Started | Runner test fixture. |
MD
  cat > "$tmpdir/.codex/zskills-config.json" <<'JSON'
{
  "execution": {
    "landing": "cherry-pick"
  },
  "runner": {
    "max_chunks": 3,
    "chunk_timeout_minutes": 12,
    "idle_timeout_minutes": 4,
    "log_dir": ".zskills/test-logs",
    "stop_marker": ".zskills/test-stop",
    "sandbox": "workspace-write",
    "approval_policy": "never"
  }
}
JSON
  printf '.zskills/tracking/\n' > "$tmpdir/.gitignore"
  git -C "$tmpdir" add .
  git -C "$tmpdir" commit -q -m init
  printf '%s\n' "$tmpdir"
}

make_multi_repo() {
  tmpdir=$(mktemp -d)
  git -C "$tmpdir" init -q
  git -C "$tmpdir" config user.email runner@example.test
  git -C "$tmpdir" config user.name "Runner Test"
  mkdir -p "$tmpdir/plans" "$tmpdir/.codex"
  cat > "$tmpdir/plans/example.md" <<'MD'
# Example Plan

## Progress Tracker

| Phase | Status | Notes |
| --- | --- | --- |
| 1. Fixture Phase One | ⬜ Not Started | Runner test fixture. |
| 2. Fixture Phase Two | ⬜ Not Started | Runner test fixture. |
| 3. Fixture Phase Three | ⬜ Not Started | Runner test fixture. |
MD
  cat > "$tmpdir/.codex/zskills-config.json" <<'JSON'
{
  "execution": {
    "landing": "cherry-pick"
  },
  "runner": {
    "max_chunks": 5,
    "chunk_timeout_minutes": 12,
    "idle_timeout_minutes": 4,
    "log_dir": ".zskills/test-logs",
    "stop_marker": ".zskills/test-stop",
    "sandbox": "workspace-write",
    "approval_policy": "never"
  }
}
JSON
  printf '.zskills/tracking/\n' > "$tmpdir/.gitignore"
  git -C "$tmpdir" add .
  git -C "$tmpdir" commit -q -m init
  printf '%s\n' "$tmpdir"
}
test_help() {
  "$SCRIPT" --help | grep -q 'finish auto'
  "$SCRIPT" --help | grep -q 'dangerously-bypass'
}

test_nonrepo_refusal() {
  local nr
  nr=$(mktemp -d)
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$nr" --dry-run >/tmp/zskills-runner-nonrepo.out 2>&1; then
    echo "expected nonrepo dry-run refusal" >&2
    exit 1
  fi
  grep -q 'repo is not a git worktree' /tmp/zskills-runner-nonrepo.out
  rm -rf "$nr" /tmp/zskills-runner-nonrepo.out
}

test_dry_run() {
  local repo
  repo=$(make_repo)
  local out
  out=$(mktemp)
  "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" --dry-run > "$out"
  grep -q '^mode=run-plan$' "$out"
  grep -q '^plan_slug=example$' "$out"
  grep -q '^max_chunks=3$' "$out"
  grep -q '^log_dir=.zskills/test-logs$' "$out"
  grep -q 'codex exec' "$out"
  grep -q -- '-c approval_policy="never"' "$out"
  ! grep -q -- '--ask-for-approval' "$out"
  rm -f "$out"
  [ -z "$(git -C "$repo" status --short)" ]
}

test_missing_codex() {
  local repo
  repo=$(make_repo)
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" --dry-run --codex-bin /no/such/codex >/tmp/zskills-runner-missing.out 2>&1; then
    echo "expected missing codex refusal" >&2
    exit 1
  fi
  grep -q 'codex executable not found' /tmp/zskills-runner-missing.out
  rm -f /tmp/zskills-runner-missing.out
}

test_dangerous_refusal() {
  local repo
  repo=$(make_repo)
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" --dry-run --dangerously-bypass-approvals-and-sandbox >/tmp/zskills-runner-danger.out 2>&1; then
    echo "expected dangerous bypass refusal" >&2
    exit 1
  fi
  grep -q 'dangerous bypass is refused' /tmp/zskills-runner-danger.out
  rm -f /tmp/zskills-runner-danger.out
}

test_no_options_parse() {
  local repo
  repo=$(make_repo)
  if ! CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=progress "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-noopts.out 2>&1; then
    echo "expected no-options execution to parse and run fake codex" >&2
    exit 1
  fi
  grep -q '^run_dir=' /tmp/zskills-runner-noopts.out
  rm -f /tmp/zskills-runner-noopts.out
  [ ! -d "$repo/.zskills/runner/example.lock" ]
}

test_preflight() {
  test_lock_conflict
  test_stale_worktree_refusal
  test_tracking_ignore_refusal
  test_merge_residue_refusal
  test_conflict_refusal
  test_direct_refusal
  test_hashes
}

test_stale_worktree_refusal() {
  local repo gitdir
  repo=$(make_repo)
  gitdir=$(git -C "$repo" rev-parse --absolute-git-dir)
  mkdir -p "$gitdir/worktrees/stale-fixture"
  printf '/tmp/does-not-exist/.git\n' > "$gitdir/worktrees/stale-fixture/gitdir"
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-stale-worktree.out 2>&1; then
    echo "expected stale worktree refusal" >&2
    exit 1
  fi
  grep -q 'stale git worktree residue present' /tmp/zskills-runner-stale-worktree.out
  rm -f /tmp/zskills-runner-stale-worktree.out
}

test_lock_conflict() {
  local repo
  repo=$(make_repo)
  mkdir -p "$repo/.zskills/runner/example.lock"
  printf 'pid=fixture\n' > "$repo/.zskills/runner/example.lock/owner"
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-lock.out 2>&1; then
    echo "expected lock refusal" >&2
    exit 1
  fi
  grep -q 'runner lock already exists' /tmp/zskills-runner-lock.out
  rm -f /tmp/zskills-runner-lock.out
}

test_tracking_ignore_refusal() {
  local repo
  repo=$(make_repo)
  printf '' > "$repo/.gitignore"
  mkdir -p "$repo/.zskills/tracking/run-plan.example"
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-ignore.out 2>&1; then
    echo "expected tracking ignore refusal" >&2
    exit 1
  fi
  grep -q '.zskills/tracking/ exists but is not ignored' /tmp/zskills-runner-ignore.out
  rm -f /tmp/zskills-runner-ignore.out
}

test_merge_residue_refusal() {
  local repo
  repo=$(make_repo)
  local gitdir
  gitdir=$(git -C "$repo" rev-parse --absolute-git-dir)
  printf 'dummy\n' > "$gitdir/MERGE_HEAD"
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-merge.out 2>&1; then
    echo "expected merge residue refusal" >&2
    exit 1
  fi
  grep -q 'MERGE_HEAD present' /tmp/zskills-runner-merge.out
  rm -f /tmp/zskills-runner-merge.out
}

test_conflict_refusal() {
  local repo
  repo=$(make_repo)
  printf '<<<<<<< ours\nx\n=======\ny\n>>>>>>> theirs\n' > "$repo/conflict.txt"
  git -C "$repo" add conflict.txt
  git -C "$repo" update-index --unresolve conflict.txt >/dev/null 2>&1 || true
  if git -C "$repo" diff --name-only --diff-filter=U | grep -q .; then
    if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-conflict.out 2>&1; then
      echo "expected conflict refusal" >&2
      exit 1
    fi
    grep -q 'unresolved conflicts' /tmp/zskills-runner-conflict.out
    rm -f /tmp/zskills-runner-conflict.out
  fi
}

test_direct_refusal() {
  local repo
  repo=$(make_repo)
  python3 - "$repo/.codex/zskills-config.json" <<'PY'
import json, sys
p = sys.argv[1]
data = json.load(open(p))
data["execution"]["landing"] = "direct"
json.dump(data, open(p, "w"))
PY
  git -C "$repo" add .codex/zskills-config.json
  git -C "$repo" commit -q -m direct-config
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-direct.out 2>&1; then
    echo "expected direct refusal" >&2
    exit 1
  fi
  grep -q 'direct landing is refused' /tmp/zskills-runner-direct.out
  rm -f /tmp/zskills-runner-direct.out
  CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=progress "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" --allow-direct-unattended >/tmp/zskills-runner-direct-allow.out 2>&1
  grep -q '^run_dir=' /tmp/zskills-runner-direct-allow.out
  rm -f /tmp/zskills-runner-direct-allow.out
}

test_direct_dirty_refusal() {
  local repo
  repo=$(make_repo)
  python3 - "$repo/.codex/zskills-config.json" <<'PY'
import json, sys
p = sys.argv[1]
data = json.load(open(p))
data["execution"]["landing"] = "direct"
data["runner"]["allow_direct_unattended"] = True
json.dump(data, open(p, "w"))
PY
  git -C "$repo" add .codex/zskills-config.json
  git -C "$repo" commit -q -m direct-config
  printf 'dirty\n' > "$repo/dirty.txt"
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-direct-dirty.out 2>&1; then
    echo "expected dirty direct refusal" >&2
    exit 1
  fi
  grep -q 'direct unattended execution requires a clean working tree' /tmp/zskills-runner-direct-dirty.out
  rm -f /tmp/zskills-runner-direct-dirty.out
}

test_direct_runner_residue_refusal() {
  local repo
  repo=$(make_repo)
  python3 - "$repo/.codex/zskills-config.json" <<'PY'
import json, sys
p = sys.argv[1]
data = json.load(open(p))
data["execution"]["landing"] = "direct"
data["runner"]["allow_direct_unattended"] = True
json.dump(data, open(p, "w"))
PY
  git -C "$repo" add .codex/zskills-config.json
  git -C "$repo" commit -q -m direct-config
  mkdir -p "$repo/.zskills/runner/other.lock"
  printf 'pid=other\n' > "$repo/.zskills/runner/other.lock/owner"
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-direct-residue.out 2>&1; then
    echo "expected unrelated runner residue refusal" >&2
    exit 1
  fi
  grep -q 'direct unattended execution requires a clean working tree' /tmp/zskills-runner-direct-residue.out
  rm -f /tmp/zskills-runner-direct-residue.out
}

test_hashes() {
  local repo
  repo=$(make_repo)
  mkdir -p "$repo/reports"
  printf '# Report\n' > "$repo/reports/plan-example.md"
  "$SCRIPT" status plans/example.md --repo "$repo" > /tmp/zskills-runner-status.out
  grep -q '^plan_hash=' /tmp/zskills-runner-status.out
  grep -q '^report_hash=' /tmp/zskills-runner-status.out
  grep -q '^tracking_dir=' /tmp/zskills-runner-status.out
  grep -q '^plan_state=' /tmp/zskills-runner-status.out
  grep -q '^report_state=' /tmp/zskills-runner-status.out
  grep -q '^tracking_state=' /tmp/zskills-runner-status.out
  rm -f /tmp/zskills-runner-status.out
}

test_initial_state_record() {
  local repo
  repo=$(make_repo)
  mkdir -p "$repo/reports" "$repo/.zskills/tracking/run-plan.example"
  printf 'Status: fixture\n' > "$repo/reports/plan-example.md"
  printf 'marker\n' > "$repo/.zskills/tracking/run-plan.example/handoff.run-plan.example.phase-0"
  local state_dir
  state_dir=$(mktemp -d)
  ZSKILLS_RUNNER_STATE_DIR="$state_dir" "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-state.out 2>&1 || true
  grep -q '^initial_state_file=' /tmp/zskills-runner-state.out
  python3 -m json.tool "$state_dir/example.initial.json" >/dev/null
  grep -q 'tracking_marker_count=1' "$state_dir/example.initial.json"
  rm -rf "$state_dir"
  rm -f /tmp/zskills-runner-state.out
}

latest_run_dir() {
  local repo="$1"
  find "$repo/.zskills/test-logs" -mindepth 1 -maxdepth 1 -type d | sort | tail -1
}

test_fake_success() {
  local repo run_dir summary
  repo=$(make_repo)
  CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=progress "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-fake-success.out
  run_dir=$(latest_run_dir "$repo")
  summary="$run_dir/chunk-001.summary.json"
  [ -f "$run_dir/chunk-001.events.jsonl" ]
  [ -f "$run_dir/chunk-001.last-message.txt" ]
  [ -f "$run_dir/runner.jsonl" ]
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["exit_code"] == 0
assert data["stop_reason"] == "chunk-exit-0"
assert data["codex_version"] == "fake-codex 1.0"
assert "command_argv" in data
assert "phase_before" in data
assert "phase_after" in data
assert data["gate_result"] == "passed"
assert data["validation_result"] == "passed"
assert data["validated_tracking_id"] == "example.phase-1"
assert "report_hash_changed" in data["progress_signals"]
PY
  grep -q 'fake progress' "$run_dir/chunk-001.last-message.txt"
  rm -f /tmp/zskills-runner-fake-success.out
}

test_progress_detected() {
  test_fake_success
}

test_no_progress_blocks() {
  local repo run_dir summary
  repo=$(make_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=no-progress "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-no-progress.out 2>&1; then
    echo "expected no-progress validation failure" >&2
    exit 1
  fi
  grep -q 'validation_failed=no durable progress detected' /tmp/zskills-runner-no-progress.out
  run_dir=$(latest_run_dir "$repo")
  summary="$run_dir/chunk-001.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["exit_code"] == 0
assert data["validation_result"] == "failed"
assert data["validation_reason"] == "no durable progress detected"
PY
  rm -f /tmp/zskills-runner-no-progress.out
}

test_missing_handoff_blocks() {
  local repo run_dir summary
  repo=$(make_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=progress-no-handoff "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-missing-handoff.out 2>&1; then
    echo "expected missing handoff validation failure" >&2
    exit 1
  fi
  grep -q 'validation_failed=handoff marker missing after progress' /tmp/zskills-runner-missing-handoff.out
  run_dir=$(latest_run_dir "$repo")
  summary="$run_dir/chunk-001.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["exit_code"] == 0
assert data["validation_result"] == "failed"
assert data["validation_reason"] == "handoff marker missing after progress"
assert data["validated_tracking_id"] == "example.phase-1"
PY
  rm -f /tmp/zskills-runner-missing-handoff.out
}

test_missing_report_blocks() {
  local repo run_dir summary
  repo=$(make_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=progress-missing-report "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-missing-report.out 2>&1; then
    echo "expected missing report validation failure" >&2
    exit 1
  fi
  grep -q 'validation_failed=report missing scope assessment' /tmp/zskills-runner-missing-report.out
  run_dir=$(latest_run_dir "$repo")
  summary="$run_dir/chunk-001.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["validation_result"] == "failed"
assert data["validation_reason"] == "report missing scope assessment"
PY
  rm -f /tmp/zskills-runner-missing-report.out
}

test_missing_scope_blocks() {
  local repo run_dir summary
  repo=$(make_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=progress-no-scope "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-missing-scope.out 2>&1; then
    echo "expected missing scope validation failure" >&2
    exit 1
  fi
  grep -q 'validation_failed=report missing scope assessment' /tmp/zskills-runner-missing-scope.out
  run_dir=$(latest_run_dir "$repo")
  summary="$run_dir/chunk-001.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["validation_result"] == "failed"
assert data["validation_reason"] == "report missing scope assessment"
PY
  rm -f /tmp/zskills-runner-missing-scope.out
}

test_missing_verifier_blocks() {
  local repo run_dir summary
  repo=$(make_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=progress-missing-verifier "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-missing-verifier.out 2>&1; then
    echo "expected missing verifier validation failure" >&2
    exit 1
  fi
  grep -q 'validation_failed=verification markers missing' /tmp/zskills-runner-missing-verifier.out
  run_dir=$(latest_run_dir "$repo")
  summary="$run_dir/chunk-001.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["validation_result"] == "failed"
assert data["validation_reason"] == "verification markers missing"
PY
  rm -f /tmp/zskills-runner-missing-verifier.out
}

test_dirty_artifact_blocks() {
  local repo run_dir summary
  repo=$(make_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=progress-dirty "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-dirty.out 2>&1; then
    echo "expected dirty artifact validation failure" >&2
    exit 1
  fi
  grep -q 'dirty-artifact.txt' /tmp/zskills-runner-dirty.out
  run_dir=$(latest_run_dir "$repo")
  summary="$run_dir/chunk-001.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["validation_result"] == "failed"
assert data["validation_reason"] in {
    "pre-continue gate failed",
    "unexpected dirty project artifact remains",
}
PY
  rm -f /tmp/zskills-runner-dirty.out
}

test_fake_fail() {
  local repo run_dir summary
  repo=$(make_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=fail "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-fake-fail.out 2>&1; then
    echo "expected fake failure to propagate" >&2
    exit 1
  fi
  run_dir=$(latest_run_dir "$repo")
  summary="$run_dir/chunk-001.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["exit_code"] == 7
assert data["stop_reason"] == "chunk-exit-7"
PY
  rm -f /tmp/zskills-runner-fake-fail.out
}

test_fake_timeout() {
  local repo run_dir summary
  repo=$(make_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=sleep FAKE_CODEX_SLEEP_SECONDS=3 ZSKILLS_RUNNER_TIMEOUT_SECONDS=1 "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-fake-timeout.out 2>&1; then
    echo "expected fake timeout to propagate" >&2
    exit 1
  fi
  run_dir=$(latest_run_dir "$repo")
  summary="$run_dir/chunk-001.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["exit_code"] == 124
assert data["stop_reason"] == "chunk-timeout"
PY
  rm -f /tmp/zskills-runner-fake-timeout.out
}

test_fake_idle_timeout() {
  local repo run_dir summary
  repo=$(make_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=idle FAKE_CODEX_SLEEP_SECONDS=3 ZSKILLS_RUNNER_IDLE_TIMEOUT_SECONDS=1 "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-fake-idle.out 2>&1; then
    echo "expected fake idle timeout to propagate" >&2
    exit 1
  fi
  run_dir=$(latest_run_dir "$repo")
  summary="$run_dir/chunk-001.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["exit_code"] == 125
assert data["stop_reason"] == "chunk-idle-timeout"
PY
  rm -f /tmp/zskills-runner-fake-idle.out
}

test_multi_chunk_completes() {
  local repo run_dir summary
  repo=$(make_multi_repo)
  CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=multi-progress "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-multi.out
  grep -q 'runner_stop_reason=complete' /tmp/zskills-runner-multi.out
  run_dir=$(latest_run_dir "$repo")
  [ -f "$run_dir/chunk-001.summary.json" ]
  [ -f "$run_dir/chunk-002.summary.json" ]
  [ -f "$run_dir/chunk-003.summary.json" ]
  [ ! -f "$run_dir/chunk-004.summary.json" ]
  summary="$run_dir/chunk-003.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" "$repo/plans/example.md" "$repo/reports/plan-example.md" <<'PY'
import json, sys
summary, plan, report = sys.argv[1:4]
data = json.load(open(summary))
assert data["runner_stop_reason"] == "complete"
assert data["validation_result"] == "passed"
assert data["validated_tracking_id"] == "example.phase-3"
plan_text = open(plan, encoding="utf-8").read()
assert "⬜ Not Started" not in plan_text
assert plan_text.count("✅ Done") == 3
report_text = open(report, encoding="utf-8").read()
assert report_text.count("Scope Assessment:") == 3
PY
  [ -z "$(git -C "$repo" status --short --untracked-files=all | grep -v '^?? .zskills/' || true)" ]
  rm -f /tmp/zskills-runner-multi.out
}

test_max_chunks_stops() {
  local repo run_dir summary
  repo=$(make_multi_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=multi-progress "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" --max-chunks 2 >/tmp/zskills-runner-max.out 2>&1; then
    echo "expected max-chunks stop" >&2
    exit 1
  fi
  grep -q 'runner_stop_reason=max-chunks' /tmp/zskills-runner-max.out
  run_dir=$(latest_run_dir "$repo")
  [ -f "$run_dir/chunk-001.summary.json" ]
  [ -f "$run_dir/chunk-002.summary.json" ]
  [ ! -f "$run_dir/chunk-003.summary.json" ]
  summary="$run_dir/chunk-002.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["runner_stop_reason"] == "max-chunks"
assert data["validated_tracking_id"] == "example.phase-2"
PY
  rm -f /tmp/zskills-runner-max.out
}

test_cherry_pick_canary() {
  local repo run_dir summary
  repo=$(make_multi_repo)
  "$SCRIPT" status plans/example.md --repo "$repo" > /tmp/zskills-runner-cherry.out
  grep -q '^execution_landing=cherry-pick$' /tmp/zskills-runner-cherry.out
  CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=multi-progress "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >/tmp/zskills-runner-cherry-run.out
  grep -q 'runner_stop_reason=complete' /tmp/zskills-runner-cherry-run.out
  run_dir=$(latest_run_dir "$repo")
  summary="$run_dir/chunk-003.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["gate_result"] == "passed"
assert data["runner_stop_reason"] == "complete"
assert "Post-run invariants: all checks passed." in data["post_run_invariants_result"]
PY
  test -f "$repo/.zskills/tracking/run-plan.example/step.run-plan.example.phase-3.land"
  test -f "$repo/.zskills/tracking/run-plan.example/fulfilled.run-plan.example.phase-3"
  rm -f /tmp/zskills-runner-cherry.out /tmp/zskills-runner-cherry-run.out
}

test_pr_dry_run() {
  local repo before after
  repo=$(make_repo)
  python3 - "$repo/.codex/zskills-config.json" <<'PY'
import json, sys
p = sys.argv[1]
data = json.load(open(p))
data["execution"]["landing"] = "pr"
data["runner"]["pr_max_rechecks"] = 0
json.dump(data, open(p, "w"))
PY
  git -C "$repo" add .codex/zskills-config.json
  git -C "$repo" commit -q -m pr-config
  before=$(git -C "$repo" rev-parse HEAD)
  "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" --dry-run > /tmp/zskills-runner-pr.out
  after=$(git -C "$repo" rev-parse HEAD)
  [ "$before" = "$after" ]
  grep -q '^execution_landing=pr$' /tmp/zskills-runner-pr.out
  grep -q 'run-plan plans/example.md finish auto' /tmp/zskills-runner-pr.out
  rm -f /tmp/zskills-runner-pr.out
}

case "$CASE" in
  help) test_help ;;
  nonrepo) test_nonrepo_refusal ;;
  dry-run) test_dry_run ;;
  missing-codex) test_missing_codex ;;
  dangerous) test_dangerous_refusal ;;
  no-options) test_no_options_parse ;;
  preflight) test_preflight ;;
  lock-conflict) test_lock_conflict ;;
  tracking-ignore) test_tracking_ignore_refusal ;;
  merge-residue) test_merge_residue_refusal ;;
  stale-worktree) test_stale_worktree_refusal ;;
  conflict) test_conflict_refusal ;;
  direct-refusal) test_direct_refusal ;;
  direct-dirty) test_direct_dirty_refusal ;;
  direct-runner-residue) test_direct_runner_residue_refusal ;;
  hashes) test_hashes ;;
  initial-state) test_initial_state_record ;;
  fake-success) test_fake_success ;;
  fake-fail) test_fake_fail ;;
  fake-timeout) test_fake_timeout ;;
  fake-idle-timeout) test_fake_idle_timeout ;;
  multi-chunk) test_multi_chunk_completes ;;
  max-chunks) test_max_chunks_stops ;;
  cherry-pick-canary) test_cherry_pick_canary ;;
  pr-dry-run) test_pr_dry_run ;;
  progress-detected) test_progress_detected ;;
  no-progress-blocks) test_no_progress_blocks ;;
  missing-handoff-blocks) test_missing_handoff_blocks ;;
  missing-report-blocks) test_missing_report_blocks ;;
  missing-scope-blocks) test_missing_scope_blocks ;;
  missing-verifier-blocks) test_missing_verifier_blocks ;;
  dirty-artifact-blocks) test_dirty_artifact_blocks ;;
  all)
    test_help
    test_nonrepo_refusal
    test_dry_run
    test_missing_codex
    test_dangerous_refusal
    test_no_options_parse
    test_preflight
    test_direct_dirty_refusal
    test_direct_runner_residue_refusal
    test_initial_state_record
    test_fake_success
    test_fake_fail
    test_no_progress_blocks
    test_missing_handoff_blocks
    test_missing_report_blocks
    test_missing_scope_blocks
    test_missing_verifier_blocks
    test_dirty_artifact_blocks
    test_multi_chunk_completes
    test_max_chunks_stops
    test_cherry_pick_canary
    test_pr_dry_run
    ;;
  *) echo "unknown test case: $CASE" >&2; exit 2 ;;
esac

echo "runner tests passed: $CASE"
