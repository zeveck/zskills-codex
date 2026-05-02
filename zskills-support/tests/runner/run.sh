#!/usr/bin/env bash
set -eu

TEST_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SUPPORT_DIR=$(cd "$TEST_DIR/../.." && pwd)
SCRIPT="$SUPPORT_DIR/scripts/zskills-runner.sh"
FAKE_CODEX="$TEST_DIR/fake-codex.sh"
CASE="${1:-all}"

tmpdir=""
outdir=""
cleanup() {
  [ -z "$tmpdir" ] || rm -rf "$tmpdir"
  [ -z "$outdir" ] || rm -rf "$outdir"
}
trap cleanup EXIT

outdir=$(mktemp -d)

make_repo() {
  tmpdir=$(mktemp -d)
  git -C "$tmpdir" init -q
  git -C "$tmpdir" config user.email runner@example.test
  git -C "$tmpdir" config user.name "Runner Test"
  mkdir -p "$tmpdir/plans" "$tmpdir/.agents"
  cat > "$tmpdir/plans/example.md" <<'MD'
# Example Plan

## Progress Tracker

| Phase | Status | Notes |
| --- | --- | --- |
| 1. Fixture Phase | ⬜ Not Started | Runner test fixture. |
MD
  cat > "$tmpdir/.agents/zskills-config.json" <<'JSON'
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
  mkdir -p "$tmpdir/plans" "$tmpdir/.agents"
  cat > "$tmpdir/plans/example.md" <<'MD'
# Example Plan

## Progress Tracker

| Phase | Status | Notes |
| --- | --- | --- |
| 1. Fixture Phase One | ⬜ Not Started | Runner test fixture. |
| 2. Fixture Phase Two | ⬜ Not Started | Runner test fixture. |
| 3. Fixture Phase Three | ⬜ Not Started | Runner test fixture. |
MD
  cat > "$tmpdir/.agents/zskills-config.json" <<'JSON'
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

runner_value() {
  local repo="$1" key="$2" plan="${3:-plans/example.md}"
  "$SCRIPT" status "$plan" --repo "$repo" | awk -F= -v k="$key" '$1 == k { print substr($0, length(k) + 2); exit }'
}

runner_plan_slug() {
  runner_value "$1" plan_slug
}

runner_plan_key() {
  runner_value "$1" plan_key
}

runner_pipeline_id() {
  runner_value "$1" pipeline_id
}

runner_report_path() {
  runner_value "$1" report_path
}

runner_tracking_dir() {
  runner_value "$1" tracking_dir
}

runner_tracking_id() {
  local repo="$1" suffix="$2"
  printf '%s.%s\n' "$(runner_plan_key "$repo")" "$suffix"
}

test_help() {
  "$SCRIPT" --help | grep -q 'finish auto'
  "$SCRIPT" --help | grep -q 'dangerously-bypass'
}

test_nonrepo_refusal() {
  local nr
  nr=$(mktemp -d)
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$nr" --dry-run >"$outdir"/zskills-runner-nonrepo.out 2>&1; then
    echo "expected nonrepo dry-run refusal" >&2
    exit 1
  fi
  grep -q 'repo is not a git worktree' "$outdir"/zskills-runner-nonrepo.out
  rm -rf "$nr" "$outdir"/zskills-runner-nonrepo.out
}

test_dry_run() {
  local repo
  repo=$(make_repo)
  local out
  out=$(mktemp)
  "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" --dry-run > "$out"
  grep -q '^mode=run-plan$' "$out"
  grep -q '^plan_slug=example$' "$out"
  grep -q '^plan_key=example-[0-9a-f][0-9a-f]*$' "$out"
  grep -q '^pipeline_id=run-plan.example-[0-9a-f][0-9a-f]*$' "$out"
  grep -q '/reports/plan-example.md$' "$out"
  grep -q '^max_chunks=3$' "$out"
  grep -q '^log_dir=.zskills/test-logs$' "$out"
  grep -q 'codex exec' "$out"
  grep -q -- '-c approval_policy="never"' "$out"
  ! grep -q -- '--ask-for-approval' "$out"
  rm -f "$out"
  [ -z "$(git -C "$repo" status --short)" ]
}

test_config_precedence() {
  local repo out
  repo=$(make_repo)
  mv "$repo/.agents/zskills-config.json" "$repo/zskills-config.json"
  mkdir -p "$repo/.codex"
  python3 - "$repo/.codex/zskills-config.json" <<'PY'
import json, sys
data = {
  "execution": {"landing": "direct"},
  "runner": {"allow_direct_unattended": True}
}
json.dump(data, open(sys.argv[1], "w"))
PY
  out=$(mktemp)
  "$SCRIPT" status plans/example.md --repo "$repo" > "$out"
  grep -q "^config=$repo/zskills-config.json$" "$out"
  grep -q '^execution_landing=cherry-pick$' "$out"
  rm -f "$out"
}

test_same_basename_disambiguates() {
  local repo out_a out_b slug_a slug_b key_a key_b pipeline_a pipeline_b
  repo=$(make_repo)
  mkdir -p "$repo/plans/alpha" "$repo/plans/beta"
  cp "$repo/plans/example.md" "$repo/plans/alpha/task.md"
  cp "$repo/plans/example.md" "$repo/plans/beta/task.md"
  git -C "$repo" add plans/alpha/task.md plans/beta/task.md
  git -C "$repo" commit -q -m same-basename-fixtures

  out_a=$(mktemp)
  out_b=$(mktemp)
  "$SCRIPT" status plans/alpha/task.md --repo "$repo" > "$out_a"
  "$SCRIPT" status plans/beta/task.md --repo "$repo" > "$out_b"
  slug_a=$(awk -F= '$1 == "plan_slug" { print substr($0, length($1) + 2); exit }' "$out_a")
  slug_b=$(awk -F= '$1 == "plan_slug" { print substr($0, length($1) + 2); exit }' "$out_b")
  key_a=$(awk -F= '$1 == "plan_key" { print substr($0, length($1) + 2); exit }' "$out_a")
  key_b=$(awk -F= '$1 == "plan_key" { print substr($0, length($1) + 2); exit }' "$out_b")
  pipeline_a=$(awk -F= '$1 == "pipeline_id" { print substr($0, length($1) + 2); exit }' "$out_a")
  pipeline_b=$(awk -F= '$1 == "pipeline_id" { print substr($0, length($1) + 2); exit }' "$out_b")

  [ "$slug_a" = "task" ] || { echo "unexpected slug: $slug_a" >&2; exit 1; }
  [ "$slug_b" = "task" ] || { echo "unexpected slug: $slug_b" >&2; exit 1; }
  case "$key_a" in task-*) ;; *) echo "unexpected key: $key_a" >&2; exit 1 ;; esac
  case "$key_b" in task-*) ;; *) echo "unexpected key: $key_b" >&2; exit 1 ;; esac
  [ "$key_a" != "$key_b" ] || { echo "same basename plans produced identical keys: $key_a" >&2; exit 1; }
  [ "$pipeline_a" != "$pipeline_b" ] || { echo "same basename plans produced identical pipeline ids: $pipeline_a" >&2; exit 1; }
  grep -q "/reports/plan-alpha-task.md" "$out_a"
  grep -q "/reports/plan-beta-task.md" "$out_b"
  ! grep -q "/reports/plan-beta-task.md" "$out_a"
  ! grep -q "/reports/plan-alpha-task.md" "$out_b"
  grep -q "/.zskills/tracking/$pipeline_a" "$out_a"
  grep -q "/.zskills/tracking/$pipeline_b" "$out_b"
  rm -f "$out_a" "$out_b"
}

test_missing_codex() {
  local repo
  repo=$(make_repo)
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" --dry-run --codex-bin /no/such/codex >"$outdir"/zskills-runner-missing.out 2>&1; then
    echo "expected missing codex refusal" >&2
    exit 1
  fi
  grep -q 'codex executable not found' "$outdir"/zskills-runner-missing.out
  rm -f "$outdir"/zskills-runner-missing.out
}

test_dangerous_refusal() {
  local repo
  repo=$(make_repo)
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" --dry-run --dangerously-bypass-approvals-and-sandbox >"$outdir"/zskills-runner-danger.out 2>&1; then
    echo "expected dangerous bypass refusal" >&2
    exit 1
  fi
  grep -q 'dangerous bypass is refused' "$outdir"/zskills-runner-danger.out
  rm -f "$outdir"/zskills-runner-danger.out
}

test_no_options_parse() {
  local repo
  repo=$(make_repo)
  if ! CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=progress "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-noopts.out 2>&1; then
    echo "expected no-options execution to parse and run fake codex" >&2
    exit 1
  fi
  grep -q '^run_dir=' "$outdir"/zskills-runner-noopts.out
  rm -f "$outdir"/zskills-runner-noopts.out
  [ -z "$(find "$repo/.zskills/runner" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)" ]
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
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-stale-worktree.out 2>&1; then
    echo "expected stale worktree refusal" >&2
    exit 1
  fi
  grep -q 'stale git worktree residue present' "$outdir"/zskills-runner-stale-worktree.out
  rm -f "$outdir"/zskills-runner-stale-worktree.out
}

test_lock_conflict() {
  local repo key
  repo=$(make_repo)
  key=$(runner_plan_key "$repo")
  mkdir -p "$repo/.zskills/runner/$key.lock"
  printf 'pid=fixture\n' > "$repo/.zskills/runner/$key.lock/owner"
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-lock.out 2>&1; then
    echo "expected lock refusal" >&2
    exit 1
  fi
  grep -q 'runner lock already exists' "$outdir"/zskills-runner-lock.out
  rm -f "$outdir"/zskills-runner-lock.out
}

test_tracking_ignore_refusal() {
  local repo
  repo=$(make_repo)
  printf '' > "$repo/.gitignore"
  mkdir -p "$(runner_tracking_dir "$repo")"
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-ignore.out 2>&1; then
    echo "expected tracking ignore refusal" >&2
    exit 1
  fi
  grep -q '.zskills/tracking/ exists but is not ignored' "$outdir"/zskills-runner-ignore.out
  rm -f "$outdir"/zskills-runner-ignore.out
}

test_merge_residue_refusal() {
  local repo
  repo=$(make_repo)
  local gitdir
  gitdir=$(git -C "$repo" rev-parse --absolute-git-dir)
  printf 'dummy\n' > "$gitdir/MERGE_HEAD"
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-merge.out 2>&1; then
    echo "expected merge residue refusal" >&2
    exit 1
  fi
  grep -q 'MERGE_HEAD present' "$outdir"/zskills-runner-merge.out
  rm -f "$outdir"/zskills-runner-merge.out
}

test_conflict_refusal() {
  local repo
  repo=$(make_repo)
  printf '<<<<<<< ours\nx\n=======\ny\n>>>>>>> theirs\n' > "$repo/conflict.txt"
  git -C "$repo" add conflict.txt
  git -C "$repo" update-index --unresolve conflict.txt >/dev/null 2>&1 || true
  if git -C "$repo" diff --name-only --diff-filter=U | grep -q .; then
    if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-conflict.out 2>&1; then
      echo "expected conflict refusal" >&2
      exit 1
    fi
    grep -q 'unresolved conflicts' "$outdir"/zskills-runner-conflict.out
    rm -f "$outdir"/zskills-runner-conflict.out
  fi
}

test_direct_refusal() {
  local repo
  repo=$(make_repo)
  python3 - "$repo/.agents/zskills-config.json" <<'PY'
import json, sys
p = sys.argv[1]
data = json.load(open(p))
data["execution"]["landing"] = "direct"
json.dump(data, open(p, "w"))
PY
  git -C "$repo" add .agents/zskills-config.json
  git -C "$repo" commit -q -m direct-config
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-direct.out 2>&1; then
    echo "expected direct refusal" >&2
    exit 1
  fi
  grep -q 'direct landing is refused' "$outdir"/zskills-runner-direct.out
  rm -f "$outdir"/zskills-runner-direct.out
  CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=progress "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" --allow-direct-unattended >"$outdir"/zskills-runner-direct-allow.out 2>&1
  grep -q '^run_dir=' "$outdir"/zskills-runner-direct-allow.out
  rm -f "$outdir"/zskills-runner-direct-allow.out
}

test_direct_dirty_refusal() {
  local repo
  repo=$(make_repo)
  python3 - "$repo/.agents/zskills-config.json" <<'PY'
import json, sys
p = sys.argv[1]
data = json.load(open(p))
data["execution"]["landing"] = "direct"
data["runner"]["allow_direct_unattended"] = True
json.dump(data, open(p, "w"))
PY
  git -C "$repo" add .agents/zskills-config.json
  git -C "$repo" commit -q -m direct-config
  printf 'dirty\n' > "$repo/dirty.txt"
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-direct-dirty.out 2>&1; then
    echo "expected dirty direct refusal" >&2
    exit 1
  fi
  grep -q 'direct unattended execution requires a clean working tree' "$outdir"/zskills-runner-direct-dirty.out
  rm -f "$outdir"/zskills-runner-direct-dirty.out
}

test_direct_runner_residue_refusal() {
  local repo
  repo=$(make_repo)
  python3 - "$repo/.agents/zskills-config.json" <<'PY'
import json, sys
p = sys.argv[1]
data = json.load(open(p))
data["execution"]["landing"] = "direct"
data["runner"]["allow_direct_unattended"] = True
json.dump(data, open(p, "w"))
PY
  git -C "$repo" add .agents/zskills-config.json
  git -C "$repo" commit -q -m direct-config
  mkdir -p "$repo/.zskills/runner/other.lock"
  printf 'pid=other\n' > "$repo/.zskills/runner/other.lock/owner"
  if "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-direct-residue.out 2>&1; then
    echo "expected unrelated runner residue refusal" >&2
    exit 1
  fi
  grep -q 'direct unattended execution requires a clean working tree' "$outdir"/zskills-runner-direct-residue.out
  rm -f "$outdir"/zskills-runner-direct-residue.out
}

test_hashes() {
  local repo report
  repo=$(make_repo)
  report=$(runner_report_path "$repo")
  mkdir -p "$repo/reports"
  printf '# Report\n' > "$report"
  "$SCRIPT" status plans/example.md --repo "$repo" > "$outdir"/zskills-runner-status.out
  grep -q '^plan_hash=' "$outdir"/zskills-runner-status.out
  grep -q '^report_hash=' "$outdir"/zskills-runner-status.out
  grep -q '^tracking_dir=' "$outdir"/zskills-runner-status.out
  grep -q '^plan_state=' "$outdir"/zskills-runner-status.out
  grep -q '^report_state=' "$outdir"/zskills-runner-status.out
  grep -q '^tracking_state=' "$outdir"/zskills-runner-status.out
  rm -f "$outdir"/zskills-runner-status.out
}

test_initial_state_record() {
  local repo state_file report tracking tracking_id
  repo=$(make_repo)
  report=$(runner_report_path "$repo")
  tracking=$(runner_tracking_dir "$repo")
  tracking_id=$(runner_tracking_id "$repo" phase-0)
  mkdir -p "$(dirname "$report")" "$tracking"
  printf 'Status: fixture\n' > "$report"
  printf 'marker\n' > "$tracking/handoff.run-plan.$tracking_id"
  local state_dir
  state_dir=$(mktemp -d)
  ZSKILLS_RUNNER_STATE_DIR="$state_dir" "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-state.out 2>&1 || true
  grep -q '^initial_state_file=' "$outdir"/zskills-runner-state.out
  state_file=$(awk -F= '$1 == "initial_state_file" { print substr($0, length($1) + 2); exit }' "$outdir"/zskills-runner-state.out)
  case "$state_file" in
    "$state_dir"/example-*.*.initial.json) ;;
    *) echo "unexpected initial state file: $state_file" >&2; exit 1 ;;
  esac
  python3 -m json.tool "$state_file" >/dev/null
  grep -q 'tracking_marker_count=1' "$state_file"
  rm -rf "$state_dir"
  rm -f "$outdir"/zskills-runner-state.out
}

latest_run_dir() {
  local repo="$1"
  find "$repo/.zskills/test-logs" -mindepth 1 -maxdepth 1 -type d | sort | tail -1
}

test_fake_success() {
  local repo run_dir summary expected_tracking_id
  repo=$(make_repo)
  expected_tracking_id=$(runner_tracking_id "$repo" phase-1)
  CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=progress "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-fake-success.out
  run_dir=$(latest_run_dir "$repo")
  summary="$run_dir/chunk-001.summary.json"
  [ -f "$run_dir/chunk-001.events.jsonl" ]
  [ -f "$run_dir/chunk-001.last-message.txt" ]
  [ -f "$run_dir/chunk-001.argv.json" ]
  [ -f "$run_dir/runner.jsonl" ]
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" "$expected_tracking_id" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
expected_tracking_id = sys.argv[2]
assert data["exit_code"] == 0
assert data["stop_reason"] == "chunk-exit-0"
assert data["codex_version"] == "fake-codex 1.0"
assert "command_argv" in data
assert "phase_before" in data
assert "phase_after" in data
assert data["gate_result"] == "passed"
assert data["validation_result"] == "passed"
assert data["validated_tracking_id"] == expected_tracking_id
assert "report_hash_changed" in data["progress_signals"]
PY
  python3 - "$run_dir/chunk-001.argv.json" <<'PY'
import json, sys
argv = json.load(open(sys.argv[1]))
prompt = argv[-1]
assert "Resolved landing mode: cherry-pick" in prompt
assert "RUNNER-MANAGED CHUNK" in prompt
assert "Do not invoke zskills-runner.sh again" in prompt
assert "You must use this mode" in prompt
assert "Do not commit phase source changes directly in the main repo for cherry-pick mode." in prompt
assert "Do not claim in the report that work was committed, cherry-picked, pushed, or fully landed until that git operation has actually succeeded." in prompt
PY
  grep -q 'fake progress' "$run_dir/chunk-001.last-message.txt"
  rm -f "$outdir"/zskills-runner-fake-success.out
}

test_progress_detected() {
  test_fake_success
}

test_no_progress_blocks() {
  local repo run_dir summary
  repo=$(make_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=no-progress "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-no-progress.out 2>&1; then
    echo "expected no-progress validation failure" >&2
    exit 1
  fi
  grep -q 'validation_failed=no durable progress detected' "$outdir"/zskills-runner-no-progress.out
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
  rm -f "$outdir"/zskills-runner-no-progress.out
}

test_missing_handoff_blocks() {
  local repo run_dir summary
  repo=$(make_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=progress-no-handoff "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-missing-handoff.out 2>&1; then
    echo "expected missing handoff validation failure" >&2
    exit 1
  fi
  grep -q 'validation_failed=handoff marker missing after progress' "$outdir"/zskills-runner-missing-handoff.out
  run_dir=$(latest_run_dir "$repo")
  summary="$run_dir/chunk-001.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["exit_code"] == 0
assert data["validation_result"] == "failed"
assert data["validation_reason"] == "handoff marker missing after progress"
assert data["validated_tracking_id"] is None
PY
  rm -f "$outdir"/zskills-runner-missing-handoff.out
}

test_premature_final_marker_blocks() {
  local repo run_dir summary expected_tracking_id
  repo=$(make_repo)
  expected_tracking_id=$(runner_tracking_id "$repo" phase-1)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=progress-premature-final "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-premature-final.out 2>&1; then
    echo "expected premature final marker validation failure" >&2
    exit 1
  fi
  grep -q 'validation_failed=final run-plan marker present before plan completion' "$outdir"/zskills-runner-premature-final.out
  run_dir=$(latest_run_dir "$repo")
  summary="$run_dir/chunk-001.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" "$expected_tracking_id" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
expected_tracking_id = sys.argv[2]
assert data["exit_code"] == 0
assert data["validation_result"] == "failed"
assert data["validation_reason"] == "final run-plan marker present before plan completion"
assert data["validated_tracking_id"] == expected_tracking_id
PY
  rm -f "$outdir"/zskills-runner-premature-final.out
}

test_missing_report_blocks() {
  local repo run_dir summary
  repo=$(make_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=progress-missing-report "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-missing-report.out 2>&1; then
    echo "expected missing report validation failure" >&2
    exit 1
  fi
  grep -q 'validation_failed=report missing scope assessment' "$outdir"/zskills-runner-missing-report.out
  run_dir=$(latest_run_dir "$repo")
  summary="$run_dir/chunk-001.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["validation_result"] == "failed"
assert data["validation_reason"] == "report missing scope assessment"
PY
  rm -f "$outdir"/zskills-runner-missing-report.out
}

test_missing_scope_blocks() {
  local repo run_dir summary
  repo=$(make_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=progress-no-scope "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-missing-scope.out 2>&1; then
    echo "expected missing scope validation failure" >&2
    exit 1
  fi
  grep -q 'validation_failed=report missing scope assessment' "$outdir"/zskills-runner-missing-scope.out
  run_dir=$(latest_run_dir "$repo")
  summary="$run_dir/chunk-001.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["validation_result"] == "failed"
assert data["validation_reason"] == "report missing scope assessment"
PY
  rm -f "$outdir"/zskills-runner-missing-scope.out
}

test_missing_verifier_blocks() {
  local repo run_dir summary
  repo=$(make_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=progress-missing-verifier "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-missing-verifier.out 2>&1; then
    echo "expected missing verifier validation failure" >&2
    exit 1
  fi
  grep -q 'validation_failed=verification markers missing' "$outdir"/zskills-runner-missing-verifier.out
  run_dir=$(latest_run_dir "$repo")
  summary="$run_dir/chunk-001.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["validation_result"] == "failed"
assert data["validation_reason"] == "verification markers missing"
PY
  rm -f "$outdir"/zskills-runner-missing-verifier.out
}

test_dirty_artifact_blocks() {
  local repo run_dir summary
  repo=$(make_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=progress-dirty "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-dirty.out 2>&1; then
    echo "expected dirty artifact validation failure" >&2
    exit 1
  fi
  grep -q 'dirty-artifact.txt' "$outdir"/zskills-runner-dirty.out
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
  rm -f "$outdir"/zskills-runner-dirty.out
}

test_fake_fail() {
  local repo run_dir summary
  repo=$(make_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=fail "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-fake-fail.out 2>&1; then
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
  rm -f "$outdir"/zskills-runner-fake-fail.out
}

test_fake_timeout() {
  local repo run_dir summary
  repo=$(make_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=sleep FAKE_CODEX_SLEEP_SECONDS=3 ZSKILLS_RUNNER_TIMEOUT_SECONDS=1 "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-fake-timeout.out 2>&1; then
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
  rm -f "$outdir"/zskills-runner-fake-timeout.out
}

test_fake_idle_timeout() {
  local repo run_dir summary
  repo=$(make_repo)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=idle FAKE_CODEX_SLEEP_SECONDS=3 ZSKILLS_RUNNER_IDLE_TIMEOUT_SECONDS=1 "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-fake-idle.out 2>&1; then
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
  rm -f "$outdir"/zskills-runner-fake-idle.out
}

test_multi_chunk_completes() {
  local repo run_dir summary report expected_tracking_id
  repo=$(make_multi_repo)
  report=$(runner_report_path "$repo")
  expected_tracking_id=$(runner_tracking_id "$repo" phase-3)
  CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=multi-progress "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-multi.out
  grep -q 'runner_stop_reason=complete' "$outdir"/zskills-runner-multi.out
  run_dir=$(latest_run_dir "$repo")
  [ -f "$run_dir/chunk-001.summary.json" ]
  [ -f "$run_dir/chunk-002.summary.json" ]
  [ -f "$run_dir/chunk-003.summary.json" ]
  [ ! -f "$run_dir/chunk-004.summary.json" ]
  summary="$run_dir/chunk-003.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" "$repo/plans/example.md" "$report" "$expected_tracking_id" <<'PY'
import json, sys
summary, plan, report, expected_tracking_id = sys.argv[1:5]
data = json.load(open(summary))
assert data["runner_stop_reason"] == "complete"
assert data["validation_result"] == "passed"
assert data["validated_tracking_id"] == expected_tracking_id
plan_text = open(plan, encoding="utf-8").read()
assert "⬜ Not Started" not in plan_text
assert plan_text.count("✅ Done") == 3
report_text = open(report, encoding="utf-8").read()
assert report_text.count("Scope Assessment:") == 3
PY
  [ -z "$(git -C "$repo" status --short --untracked-files=all | grep -v '^?? .zskills/' || true)" ]
  rm -f "$outdir"/zskills-runner-multi.out
}

test_reused_handoff_validates() {
  local repo run_dir summary report tracking tracking_id
  repo=$(make_multi_repo)
  report=$(runner_report_path "$repo")
  tracking=$(runner_tracking_dir "$repo")
  tracking_id=$(runner_tracking_id "$repo" phase-1)
  python3 - "$repo/plans/example.md" <<'PY'
import re
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text = re.sub(r"⬜ Not Started", "✅ Done", text, count=1)
open(path, "w", encoding="utf-8").write(text)
PY
  mkdir -p "$(dirname "$report")" "$tracking"
  cat > "$report" <<'MD'
# Example Plan Report

## Phase 1: Fixture Progress

Status: verified.

Scope Assessment:

- Fixture-only initial progress for runner validation.

Verification:

- fake verifier passed.
MD
  printf 'handoff phase 1\n' > "$tracking/handoff.run-plan.$tracking_id"
  git -C "$repo" add plans/example.md "$report"
  git -C "$repo" commit -q -m "fixture phase 1 complete"

  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=reuse-handoff-progress "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" --max-chunks 1 >"$outdir"/zskills-runner-reuse-handoff.out 2>&1; then
    echo "expected max-chunks stop after one validated reused-handoff chunk" >&2
    exit 1
  fi
  grep -q 'runner_stop_reason=max-chunks' "$outdir"/zskills-runner-reuse-handoff.out
  ! grep -q 'validation_failed=handoff marker missing after progress' "$outdir"/zskills-runner-reuse-handoff.out
  run_dir=$(latest_run_dir "$repo")
  summary="$run_dir/chunk-001.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" "$tracking_id" <<'PY'
import json
import sys
data = json.load(open(sys.argv[1]))
expected_tracking_id = sys.argv[2]
assert data["validation_result"] == "passed"
assert data["validated_tracking_id"] == expected_tracking_id
assert "changed_handoff_run_plan" in data["progress_signals"]
assert data["runner_stop_reason"] == "max-chunks"
PY
  rm -f "$outdir"/zskills-runner-reuse-handoff.out
}

test_max_chunks_stops() {
  local repo run_dir summary expected_tracking_id
  repo=$(make_multi_repo)
  expected_tracking_id=$(runner_tracking_id "$repo" phase-2)
  if CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=multi-progress "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" --max-chunks 2 >"$outdir"/zskills-runner-max.out 2>&1; then
    echo "expected max-chunks stop" >&2
    exit 1
  fi
  grep -q 'runner_stop_reason=max-chunks' "$outdir"/zskills-runner-max.out
  run_dir=$(latest_run_dir "$repo")
  [ -f "$run_dir/chunk-001.summary.json" ]
  [ -f "$run_dir/chunk-002.summary.json" ]
  [ ! -f "$run_dir/chunk-003.summary.json" ]
  summary="$run_dir/chunk-002.summary.json"
  python3 -m json.tool "$summary" >/dev/null
  python3 - "$summary" "$expected_tracking_id" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
expected_tracking_id = sys.argv[2]
assert data["runner_stop_reason"] == "max-chunks"
assert data["validated_tracking_id"] == expected_tracking_id
PY
  rm -f "$outdir"/zskills-runner-max.out
}

test_cherry_pick_canary() {
  local repo run_dir summary tracking tracking_id
  repo=$(make_multi_repo)
  tracking=$(runner_tracking_dir "$repo")
  tracking_id=$(runner_tracking_id "$repo" phase-3)
  "$SCRIPT" status plans/example.md --repo "$repo" > "$outdir"/zskills-runner-cherry.out
  grep -q '^execution_landing=cherry-pick$' "$outdir"/zskills-runner-cherry.out
  CODEX_BIN="$FAKE_CODEX" FAKE_CODEX_MODE=multi-progress "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" >"$outdir"/zskills-runner-cherry-run.out
  grep -q 'runner_stop_reason=complete' "$outdir"/zskills-runner-cherry-run.out
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
  test -f "$tracking/step.run-plan.$tracking_id.land"
  test -f "$tracking/fulfilled.run-plan.$tracking_id"
  rm -f "$outdir"/zskills-runner-cherry.out "$outdir"/zskills-runner-cherry-run.out
}

test_pr_dry_run() {
  local repo before after
  repo=$(make_repo)
  python3 - "$repo/.agents/zskills-config.json" <<'PY'
import json, sys
p = sys.argv[1]
data = json.load(open(p))
data["execution"]["landing"] = "pr"
data["runner"]["pr_max_rechecks"] = 0
json.dump(data, open(p, "w"))
PY
  git -C "$repo" add .agents/zskills-config.json
  git -C "$repo" commit -q -m pr-config
  before=$(git -C "$repo" rev-parse HEAD)
  "$SCRIPT" run-plan plans/example.md finish auto --repo "$repo" --dry-run > "$outdir"/zskills-runner-pr.out
  after=$(git -C "$repo" rev-parse HEAD)
  [ "$before" = "$after" ]
  grep -q '^execution_landing=pr$' "$outdir"/zskills-runner-pr.out
  grep -q 'run-plan plans/example.md finish auto' "$outdir"/zskills-runner-pr.out
  rm -f "$outdir"/zskills-runner-pr.out
}

case "$CASE" in
  help) test_help ;;
  nonrepo) test_nonrepo_refusal ;;
  dry-run) test_dry_run ;;
  config-precedence) test_config_precedence ;;
  same-basename) test_same_basename_disambiguates ;;
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
  reused-handoff) test_reused_handoff_validates ;;
  max-chunks) test_max_chunks_stops ;;
  cherry-pick-canary) test_cherry_pick_canary ;;
  pr-dry-run) test_pr_dry_run ;;
  progress-detected) test_progress_detected ;;
  no-progress-blocks) test_no_progress_blocks ;;
  missing-handoff-blocks) test_missing_handoff_blocks ;;
  premature-final-blocks) test_premature_final_marker_blocks ;;
  missing-report-blocks) test_missing_report_blocks ;;
  missing-scope-blocks) test_missing_scope_blocks ;;
  missing-verifier-blocks) test_missing_verifier_blocks ;;
  dirty-artifact-blocks) test_dirty_artifact_blocks ;;
  all)
    test_help
    test_nonrepo_refusal
    test_dry_run
    test_config_precedence
    test_same_basename_disambiguates
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
    test_premature_final_marker_blocks
    test_missing_report_blocks
    test_missing_scope_blocks
    test_missing_verifier_blocks
    test_dirty_artifact_blocks
    test_multi_chunk_completes
    test_reused_handoff_validates
    test_max_chunks_stops
    test_cherry_pick_canary
    test_pr_dry_run
    ;;
  *) echo "unknown test case: $CASE" >&2; exit 2 ;;
esac

echo "runner tests passed: $CASE"
