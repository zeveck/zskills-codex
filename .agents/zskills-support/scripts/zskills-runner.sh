#!/usr/bin/env bash
# Codex-native external runner skeleton for Z Skills chunked finish-auto.
# Implements parsing, config discovery, preflight gates, and one fresh chunk
# execution with structured logging.

set -u

SUPPORT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SANITIZE="$SUPPORT_DIR/scripts/sanitize-pipeline-id.sh"

usage() {
  cat <<'EOF'
Usage:
  zskills-runner.sh --help
  zskills-runner.sh status <plan> [--repo <path>]
  zskills-runner.sh stop <plan> [--repo <path>]
  zskills-runner.sh run-plan <plan> finish auto [options]

Options:
  --repo <path>                 Git repository to run from. Default: current directory.
  --dry-run                     Resolve config and print intended codex exec argv; mutate nothing.
  --max-chunks <n>              Override runner.max_chunks.
  --chunk-timeout-min <n>       Override runner.chunk_timeout_minutes.
  --idle-timeout-min <n>        Override runner.idle_timeout_minutes.
  --log-dir <path>              Override runner.log_dir.
  --stop-marker <path>          Override runner.stop_marker.
  --sandbox <mode>              read-only, workspace-write, or danger-full-access.
  --approval-policy <policy>    never, on-request, or untrusted.
  --codex-bin <path>            Codex executable. Default: CODEX_BIN or codex in PATH.
  --codex-arg <arg>             Additional child codex arg. Repeated.
  --allow-direct-unattended     Override runner.allow_direct_unattended for this run.

Safety defaults:
  - Uses fresh codex exec invocations; never codex exec resume.
  - Refuses --dangerously-bypass-approvals-and-sandbox.
  - Refuses non-git repositories.
  - Direct unattended execution is refused unless explicitly configured.
EOF
}

die() {
  echo "zskills-runner: $*" >&2
  exit 2
}

json_get() {
  local file="$1" expr="$2" default="$3"
  [ -f "$file" ] || { printf '%s\n' "$default"; return; }
  python3 - "$file" "$expr" "$default" <<'PY'
import json, sys
path, expr, default = sys.argv[1:4]
try:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    cur = data
    for part in expr.split("."):
        cur = cur[part]
    if isinstance(cur, bool):
        print("true" if cur else "false")
    else:
        print(cur)
except Exception:
    print(default)
PY
}

sha_file() {
  local file="$1"
  if [ -f "$file" ]; then
    sha256sum "$file" | awk '{print $1}'
  else
    printf '<missing>\n'
  fi
}

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().rstrip("\n")))'
}

abs_runner_path() {
  local path="$1"
  case "$path" in
    /*) printf '%s\n' "$path" ;;
    *) printf '%s\n' "$REPO_ROOT/$path" ;;
  esac
}

resolve_plan_path() {
  local repo="$1" plan="$2"
  case "$plan" in
    /*) printf '%s\n' "$plan" ;;
    *) printf '%s\n' "$repo/$plan" ;;
  esac
}

report_path() {
  local repo="$1" report_slug="$2"
  printf '%s/reports/plan-%s.md\n' "$repo" "$report_slug"
}

tracking_dir() {
  local repo="$1" pipeline="$2"
  printf '%s/.zskills/tracking/%s\n' "$repo" "$pipeline"
}

plan_state() {
  local file="$1"
  if [ ! -f "$file" ]; then
    printf 'plan_state=missing\n'
    return
  fi
  python3 - "$file" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
done = len(re.findall(r"✅\s*Done|\[[xX]\]\s*Phase\b", text))
in_progress = len(re.findall(r"🟡\s*In Progress", text))
not_started = len(re.findall(r"⬜\s*Not Started|\[\s\]\s*Phase\b", text))
print(f"plan_state=present")
print(f"plan_done_count={done}")
print(f"plan_in_progress_count={in_progress}")
print(f"plan_not_started_count={not_started}")
PY
}

report_state() {
  local file="$1"
  if [ ! -f "$file" ]; then
    printf 'report_state=missing\n'
    return
  fi
  python3 - "$file" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
statuses = re.findall(r"^Status:\s*(.+)$", text, flags=re.M)
phases = re.findall(r"^## Phase\s+(.+)$", text, flags=re.M)
print("report_state=present")
print(f"report_phase_count={len(phases)}")
print(f"report_last_status={statuses[-1] if statuses else '<none>'}")
PY
}

marker_state() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    printf 'tracking_state=missing\n'
    printf 'tracking_marker_count=0\n'
    printf 'tracking_marker_hashes=\n'
    return
  fi
  printf 'tracking_state=present\n'
  python3 - "$dir" <<'PY'
import hashlib
import os
import sys

root = sys.argv[1]
names = sorted(
    name for name in os.listdir(root)
    if os.path.isfile(os.path.join(root, name))
)
hashes = []
for name in names:
    path = os.path.join(root, name)
    digest = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            digest.update(chunk)
    hashes.append(f"{name}:{digest.hexdigest()}")

print(f"tracking_marker_count={len(names)}")
print("tracking_markers=" + ",".join(names))
print("tracking_marker_hashes=" + ",".join(hashes))
PY
}

state_value() {
  local file="$1" key="$2"
  awk -F= -v k="$key" '$1 == k { print substr($0, length(k) + 2); exit }' "$file"
}

tracking_markers_csv() {
  state_value "$1" "tracking_markers"
}

tracking_marker_hashes_csv() {
  state_value "$1" "tracking_marker_hashes"
}

csv_has_marker() {
  local csv="$1" marker="$2"
  case ",$csv," in
    *,"$marker",*) return 0 ;;
    *) return 1 ;;
  esac
}

new_tracking_marker() {
  local before_csv="$1" after_csv="$2" prefix="$3"
  python3 - "$before_csv" "$after_csv" "$prefix" <<'PY'
import sys
before = set(filter(None, sys.argv[1].split(",")))
after = set(filter(None, sys.argv[2].split(",")))
prefix = sys.argv[3]
matches = sorted(m for m in after - before if m.startswith(prefix))
if matches:
    print(matches[-1])
PY
}

changed_tracking_marker() {
  local before_hashes="$1" after_hashes="$2" prefix="$3"
  python3 - "$before_hashes" "$after_hashes" "$prefix" <<'PY'
import sys

def parse(value):
    result = {}
    for item in filter(None, value.split(",")):
        name, sep, digest = item.partition(":")
        if sep:
            result[name] = digest
    return result

before = parse(sys.argv[1])
after = parse(sys.argv[2])
prefix = sys.argv[3]
matches = sorted(
    name for name, digest in after.items()
    if name.startswith(prefix) and name in before and before[name] != digest
)
if matches:
    print(matches[-1])
PY
}

tracking_id_from_marker() {
  local marker="$1" prefix="$2"
  printf '%s\n' "${marker#"$prefix"}"
}

plan_is_complete() {
  local after_file="$1" not_started in_progress
  not_started=$(state_value "$after_file" "plan_not_started_count")
  in_progress=$(state_value "$after_file" "plan_in_progress_count")
  [ "${not_started:-1}" = "0" ] && [ "${in_progress:-1}" = "0" ]
}

dirty_project_artifacts() {
  local root status path
  for root in "$REPO_ROOT" "$(active_artifact_root)"; do
    [ -n "$root" ] || continue
    [ -d "$root" ] || continue
    status=$(git -C "$root" status --short --untracked-files=all)
    [ -z "$status" ] && continue
    while IFS= read -r line; do
      path=${line#???}
      case "$path" in
        .zskills/*|.zskills-tracked) ;;
        *) printf '%s: %s\n' "$root" "$line"; return 1 ;;
      esac
    done <<EOF
$status
EOF
  done
  return 0
}

update_summary_validation() {
  local summary_file="$1" validation_result="$2" validation_reason="$3" tracking_id="$4" gate_result="$5" invariant_result="$6" signals="$7"
  python3 - "$summary_file" "$validation_result" "$validation_reason" "$tracking_id" "$gate_result" "$invariant_result" "$signals" <<'PY'
import json
import sys

summary_file, validation_result, validation_reason, tracking_id, gate_result, invariant_result, signals = sys.argv[1:8]
with open(summary_file, encoding="utf-8") as f:
    data = json.load(f)
data["validation_result"] = validation_result
data["validation_reason"] = validation_reason
data["validated_tracking_id"] = tracking_id or None
data["gate_result"] = gate_result
data["post_run_invariants_result"] = invariant_result
data["progress_signals"] = [s for s in signals.split(",") if s]
with open(summary_file, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
}

validate_report_evidence() {
  local report="$1"
  [ -f "$report" ] || return 1
  grep -qi 'scope assessment' "$report" || return 2
  return 0
}

validate_marker_evidence() {
  local tracking="$1" tracking_id="$2"
  local marker
  for marker in \
    "step.run-plan.$tracking_id.implement" \
    "step.run-plan.$tracking_id.verify" \
    "step.run-plan.$tracking_id.report" \
    "requires.verify-changes.$tracking_id" \
    "step.verify-changes.$tracking_id.complete" \
    "fulfilled.verify-changes.$tracking_id"; do
    [ -e "$tracking/$marker" ] || return 1
  done
  return 0
}

run_pre_continue_gate() {
  local tracking_id="$1" gate_out="$2" mode="${3:-pre-continue}"
  local artifact_root
  artifact_root=$(active_artifact_root)
  "$SUPPORT_DIR/scripts/zskills-gate.sh" \
    --repo "$REPO_ROOT" \
    --mode "$mode" \
    --pipeline "$PIPELINE_ID" \
    --tracking-id "$tracking_id" \
    --plan-slug "$PLAN_SLUG" \
    --plan-file "$(resolve_plan_path "$artifact_root" "$PLAN")" \
    --report "$(report_path "$artifact_root" "$PLAN_REPORT_SLUG")" >"$gate_out" 2>&1
}

run_post_run_invariants_if_available() {
  local tracking_id="$1" invariant_out="$2"
  local tracking
  tracking=$(tracking_dir "$REPO_ROOT" "$PIPELINE_ID")
  if [ ! -e "$tracking/step.run-plan.$tracking_id.land" ] && [ ! -e "$tracking/fulfilled.run-plan.$tracking_id" ]; then
    printf 'not-run-no-landed-state\n' > "$invariant_out"
    return 0
  fi
  (
    cd "$REPO_ROOT"
    "$SUPPORT_DIR/scripts/post-run-invariants.sh" \
      --worktree "" \
      --branch "" \
      --landed-status landed \
      --plan-slug "$PLAN_SLUG" \
      --report "$(report_path "$REPO_ROOT" "$PLAN_REPORT_SLUG")" \
      --plan-file "$(resolve_plan_path "$REPO_ROOT" "$PLAN")" \
      --base-branch "$BASE_BRANCH" \
      --remote "$REMOTE"
  ) >"$invariant_out" 2>&1
}

shared_worktree_path() {
  local project
  project=$(basename "$REPO_ROOT")
  printf '/tmp/%s-run-plan-%s\n' "$project" "$PLAN_KEY"
}

shared_worktree_branch() {
  printf '%s%s\n' "$BRANCH_PREFIX" "run-plan/$PLAN_KEY"
}

active_artifact_root() {
  local wt
  wt=$(shared_worktree_path)
  case "$EXECUTION_LANDING" in
    cherry-pick|pr)
      if [ -d "$wt" ] && git -C "$wt" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        printf '%s\n' "$wt"
        return 0
      fi
      ;;
  esac
  printf '%s\n' "$REPO_ROOT"
}

runner_stop_reason() {
  local summary_file="$1" stop_reason="$2"
  python3 - "$summary_file" "$stop_reason" <<'PY'
import json
import sys
path, stop_reason = sys.argv[1:3]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
data["runner_stop_reason"] = stop_reason
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
}

validate_chunk_progress() {
  local run_dir="$1" summary_file="$2" before_file="$3" after_file="$4" chunk_label="$5"
  local before_plan_hash after_plan_hash before_report_hash after_report_hash before_markers after_markers before_marker_hashes after_marker_hashes
  local new_handoff changed_handoff valid_handoff new_fulfilled changed_fulfilled valid_fulfilled tracking_id signals report tracking gate_out invariant_out dirty complete gate_mode
  before_plan_hash=$(state_value "$before_file" "plan_hash")
  after_plan_hash=$(state_value "$after_file" "plan_hash")
  before_report_hash=$(state_value "$before_file" "report_hash")
  after_report_hash=$(state_value "$after_file" "report_hash")
  before_markers=$(tracking_markers_csv "$before_file")
  after_markers=$(tracking_markers_csv "$after_file")
  before_marker_hashes=$(tracking_marker_hashes_csv "$before_file")
  after_marker_hashes=$(tracking_marker_hashes_csv "$after_file")
  new_handoff=$(new_tracking_marker "$before_markers" "$after_markers" "handoff.run-plan.")
  changed_handoff=$(changed_tracking_marker "$before_marker_hashes" "$after_marker_hashes" "handoff.run-plan.")
  valid_handoff="${new_handoff:-$changed_handoff}"
  new_fulfilled=$(new_tracking_marker "$before_markers" "$after_markers" "fulfilled.run-plan.")
  changed_fulfilled=$(changed_tracking_marker "$before_marker_hashes" "$after_marker_hashes" "fulfilled.run-plan.")
  valid_fulfilled="${new_fulfilled:-$changed_fulfilled}"
  signals=""
  [ "$before_plan_hash" != "$after_plan_hash" ] && signals="${signals},plan_hash_changed"
  [ "$before_report_hash" != "$after_report_hash" ] && signals="${signals},report_hash_changed"
  [ -n "$new_fulfilled" ] && signals="${signals},new_fulfilled_run_plan"
  [ -n "$new_handoff" ] && signals="${signals},new_handoff_run_plan"
  [ -n "$changed_fulfilled" ] && signals="${signals},changed_fulfilled_run_plan"
  [ -n "$changed_handoff" ] && signals="${signals},changed_handoff_run_plan"
  signals=${signals#,}

  gate_out="$run_dir/$chunk_label.gate.txt"
  invariant_out="$run_dir/$chunk_label.post-run-invariants.txt"
  report=$(report_path "$(active_artifact_root)" "$PLAN_REPORT_SLUG")
  tracking=$(tracking_dir "$REPO_ROOT" "$PIPELINE_ID")
  complete=false
  plan_is_complete "$after_file" && complete=true

  if [ -z "$signals" ]; then
    update_summary_validation "$summary_file" "failed" "no durable progress detected" "" "not-run-no-progress" "not-run" "$signals"
    echo "validation_failed=no durable progress detected" >&2
    return 20
  fi

  if [ -n "$valid_handoff" ]; then
    tracking_id=$(tracking_id_from_marker "$valid_handoff" "handoff.run-plan.")
  elif [ -n "$valid_fulfilled" ]; then
    tracking_id=$(tracking_id_from_marker "$valid_fulfilled" "fulfilled.run-plan.")
  else
    tracking_id=""
  fi

  if [ "$complete" != "true" ] && [ -z "$valid_handoff" ]; then
    update_summary_validation "$summary_file" "failed" "handoff marker missing after progress" "$tracking_id" "not-run-missing-handoff" "not-run" "$signals"
    echo "validation_failed=handoff marker missing after progress" >&2
    return 21
  fi

  if [ "$complete" != "true" ] && [ -n "$tracking_id" ]; then
    if [ -e "$tracking/step.run-plan.$tracking_id.land" ] || [ -e "$tracking/fulfilled.run-plan.$tracking_id" ]; then
      update_summary_validation "$summary_file" "failed" "final run-plan marker present before plan completion" "$tracking_id" "not-run-premature-final-marker" "not-run" "$signals"
      echo "validation_failed=final run-plan marker present before plan completion" >&2
      return 21
    fi
  fi

  if ! validate_report_evidence "$report"; then
    update_summary_validation "$summary_file" "failed" "report missing scope assessment" "$tracking_id" "not-run-report-invalid" "not-run" "$signals"
    echo "validation_failed=report missing scope assessment" >&2
    return 22
  fi

  if [ -z "$tracking_id" ]; then
    update_summary_validation "$summary_file" "failed" "tracking id missing after progress" "" "not-run-missing-tracking-id" "not-run" "$signals"
    echo "validation_failed=tracking id missing after progress" >&2
    return 23
  fi

  if ! validate_marker_evidence "$tracking" "$tracking_id"; then
    update_summary_validation "$summary_file" "failed" "verification markers missing" "$tracking_id" "not-run-markers-invalid" "not-run" "$signals"
    echo "validation_failed=verification markers missing" >&2
    return 23
  fi

  if [ "$complete" = "true" ]; then
    gate_mode="post-land"
  else
    gate_mode="pre-continue"
  fi
  if run_pre_continue_gate "$tracking_id" "$gate_out" "$gate_mode"; then
    gate_result="passed"
  else
    gate_result="failed"
    update_summary_validation "$summary_file" "failed" "pre-continue gate failed" "$tracking_id" "$gate_result" "not-run" "$signals"
    cat "$gate_out" >&2
    return 24
  fi

  dirty=$(dirty_project_artifacts || true)
  if [ -n "$dirty" ]; then
    update_summary_validation "$summary_file" "failed" "unexpected dirty project artifact remains" "$tracking_id" "$gate_result" "not-run" "$signals"
    printf '%s\n' "$dirty" >&2
    return 25
  fi

  run_post_run_invariants_if_available "$tracking_id" "$invariant_out"
  invariant_result=$(tr '\n' ' ' < "$invariant_out" | sed 's/[[:space:]]*$//')
  update_summary_validation "$summary_file" "passed" "durable progress validated" "$tracking_id" "$gate_result" "$invariant_result" "$signals"
  echo "validation_result=passed"
  echo "validated_tracking_id=$tracking_id"
  return 0
}

find_config() {
  local repo="$1"
  if [ -f "$repo/.agents/zskills-config.json" ]; then
    printf '%s\n' "$repo/.agents/zskills-config.json"
  elif [ -f "$repo/zskills-config.json" ]; then
    printf '%s\n' "$repo/zskills-config.json"
  elif [ -f "$repo/.codex/zskills-config.json" ]; then
    printf '%s\n' "$repo/.codex/zskills-config.json"
  elif [ -f "$repo/.claude/zskills-config.json" ]; then
    printf '%s\n' "$repo/.claude/zskills-config.json"
  else
    printf '\n'
  fi
}

sanitize_id() {
  if [ -x "$SANITIZE" ]; then
    "$SANITIZE" "$1"
  else
    printf '%s' "$1" | tr -c 'a-zA-Z0-9._-' '_' | head -c 128
  fi
}

plan_slug() {
  local plan="$1"
  local base
  base=$(basename "$plan")
  base=${base%.*}
  sanitize_id "$base"
}

plan_key() {
  local plan="$1"
  local slug rel digest
  slug=$(plan_slug "$plan")
  rel=$(python3 - "$REPO_ROOT" "$plan" <<'PY'
import os
import sys

repo, plan = sys.argv[1:3]
path = plan if os.path.isabs(plan) else os.path.join(repo, plan)
print(os.path.relpath(os.path.normpath(path), os.path.normpath(repo)))
PY
)
  digest=$(printf '%s' "$rel" | sha256sum | awk '{print substr($1, 1, 10)}')
  printf '%s-%s\n' "$slug" "$digest"
}

plan_report_slug() {
  local plan="$1"
  python3 - "$REPO_ROOT" "$plan" <<'PY'
import os
import re
import sys

repo, plan = sys.argv[1:3]
path = plan if os.path.isabs(plan) else os.path.join(repo, plan)
rel = os.path.relpath(os.path.normpath(path), os.path.normpath(repo))
parts = rel.split(os.sep)
if len(parts) > 1 and parts[0] == "plans":
    rel = os.path.join(*parts[1:])
base, _ = os.path.splitext(rel)
slug = re.sub(r"[^A-Za-z0-9._-]+", "-", base).strip("-")
print(slug[:128] or "plan")
PY
}

git_repo_root() {
  local repo="$1"
  git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  git -C "$repo" rev-parse --show-toplevel
}

contains_dangerous_arg() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      --dangerously-bypass-approvals-and-sandbox|*dangerously-bypass-approvals-and-sandbox*)
        return 0
        ;;
    esac
  done
  return 1
}

print_resolved() {
  local artifact_root plan_path report tracking shared_wt shared_branch
  artifact_root=$(active_artifact_root)
  plan_path=$(resolve_plan_path "$artifact_root" "$PLAN")
  report=$(report_path "$artifact_root" "$PLAN_REPORT_SLUG")
  tracking=$(tracking_dir "$REPO_ROOT" "$PIPELINE_ID")
  shared_wt=$(shared_worktree_path)
  shared_branch=$(shared_worktree_branch)
  cat <<EOF
mode=$MODE
repo=$REPO_ROOT
artifact_root=$artifact_root
plan=$PLAN
plan_path=$plan_path
plan_slug=$PLAN_SLUG
plan_report_slug=$PLAN_REPORT_SLUG
plan_key=$PLAN_KEY
pipeline_id=$PIPELINE_ID
tracking_dir=$tracking
report_path=$report
plan_hash=$(sha_file "$plan_path")
report_hash=$(sha_file "$report")
config=${CONFIG_FILE:-<none>}
max_chunks=$MAX_CHUNKS
chunk_timeout_minutes=$CHUNK_TIMEOUT_MINUTES
idle_timeout_minutes=$IDLE_TIMEOUT_MINUTES
log_dir=$LOG_DIR
stop_marker=$STOP_MARKER
sandbox=$SANDBOX
approval_policy=$APPROVAL_POLICY
execution_landing=$EXECUTION_LANDING
shared_worktree_path=$shared_wt
shared_worktree_branch=$shared_branch
allow_direct_unattended=$ALLOW_DIRECT_UNATTENDED
codex_bin=$CODEX_BIN
codex_argv=${CODEX_ARGV[*]}
EOF
  plan_state "$plan_path"
  report_state "$report"
  marker_state "$tracking"
}

write_initial_state() {
  local state_dir plan_path report tracking state_file tmp repo_key
  state_dir="${ZSKILLS_RUNNER_STATE_DIR:-/tmp/zskills-runner-state}"
  plan_path=$(resolve_plan_path "$REPO_ROOT" "$PLAN")
  report=$(report_path "$REPO_ROOT" "$PLAN_REPORT_SLUG")
  tracking=$(tracking_dir "$REPO_ROOT" "$PIPELINE_ID")
  repo_key=$(printf '%s' "$REPO_ROOT" | sha256sum | awk '{print substr($1, 1, 12)}')
  mkdir -p "$state_dir"
  state_file="$state_dir/$PLAN_KEY.$repo_key.initial.json"
  tmp=$(mktemp)
  print_resolved > "$tmp"
  {
    printf '{\n'
    printf '  "plan": %s,\n' "$(printf '%s' "$PLAN" | json_escape)"
    printf '  "repo": %s,\n' "$(printf '%s' "$REPO_ROOT" | json_escape)"
    printf '  "plan_path": %s,\n' "$(printf '%s' "$plan_path" | json_escape)"
    printf '  "report_path": %s,\n' "$(printf '%s' "$report" | json_escape)"
    printf '  "tracking_dir": %s,\n' "$(printf '%s' "$tracking" | json_escape)"
    printf '  "captured_at": %s,\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ | json_escape)"
    printf '  "state_lines": [\n'
    python3 - "$tmp" <<'PY'
import json, sys
lines = [line.rstrip("\n") for line in open(sys.argv[1], encoding="utf-8")]
for i, line in enumerate(lines):
    comma = "," if i < len(lines) - 1 else ""
    print("    " + json.dumps(line) + comma)
PY
    printf '  ]\n'
    printf '}\n'
  } > "$state_file"
  rm -f "$tmp"
  echo "initial_state_file=$state_file"
}

collect_state_file() {
  local file="$1"
  print_resolved > "$file"
}

codex_version() {
  "$CODEX_BIN" --version 2>/dev/null | head -1 || printf '<unknown>\n'
}

tracking_is_ignored() {
  local dir="$REPO_ROOT/.zskills/tracking"
  [ -e "$dir" ] || return 0
  git -C "$REPO_ROOT" check-ignore -q "$dir" 2>/dev/null
}

has_unresolved_conflicts() {
  [ -n "$(git -C "$REPO_ROOT" diff --name-only --diff-filter=U)" ]
}

has_pre_cherry_pick_stash() {
  git -C "$REPO_ROOT" stash list | grep -q 'pre-cherry-pick'
}

tree_is_clean() {
  local status
  status=$(git -C "$REPO_ROOT" status --short --untracked-files=all)
  [ -z "$status" ] && return 0
  while IFS= read -r line; do
    path=${line#???}
    case "$path" in
      .zskills/runner/"$PLAN_KEY.lock"|.zskills/runner/"$PLAN_KEY.lock"/*) ;;
      *) return 1 ;;
    esac
  done <<EOF
$status
EOF
  return 0
}

refuse_git_residue() {
  local git_dir
  git_dir=$(git -C "$REPO_ROOT" rev-parse --absolute-git-dir)
  [ ! -e "$git_dir/CHERRY_PICK_HEAD" ] || die "unsafe git state: CHERRY_PICK_HEAD present"
  [ ! -e "$git_dir/MERGE_HEAD" ] || die "unsafe git state: MERGE_HEAD present"
  [ ! -e "$git_dir/REBASE_HEAD" ] || die "unsafe git state: REBASE_HEAD present"
  [ ! -d "$git_dir/rebase-merge" ] || die "unsafe git state: rebase-merge present"
  [ ! -d "$git_dir/rebase-apply" ] || die "unsafe git state: rebase-apply present"
  ! has_unresolved_conflicts || die "unsafe git state: unresolved conflicts present"
  ! has_pre_cherry_pick_stash || die "unsafe git state: pre-cherry-pick stash present"
  [ -z "$(git -C "$REPO_ROOT" worktree prune --dry-run --verbose 2>&1)" ] || die "unsafe git state: stale git worktree residue present"
}

acquire_lock() {
  LOCK_DIR="$REPO_ROOT/.zskills/runner/$PLAN_KEY.lock"
  if mkdir -p "$REPO_ROOT/.zskills/runner" && mkdir "$LOCK_DIR" 2>/dev/null; then
    printf 'pid=%s\nstarted_at=%s\nplan=%s\n' "$$" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$PLAN" > "$LOCK_DIR/owner"
    trap 'rm -rf "$LOCK_DIR"' EXIT
    return 0
  fi
  if [ -f "$LOCK_DIR/owner" ]; then
    die "runner lock already exists: $LOCK_DIR ($(tr '\n' ' ' < "$LOCK_DIR/owner"))"
  fi
  die "runner lock already exists: $LOCK_DIR"
}

preflight() {
  refuse_git_residue
  tracking_is_ignored || die ".zskills/tracking/ exists but is not ignored by git"
  if [ "$EXECUTION_LANDING" = "direct" ] && [ "$ALLOW_DIRECT_UNATTENDED" != "true" ]; then
    die "direct landing is refused for unattended runner execution"
  fi
  if [ "$EXECUTION_LANDING" = "direct" ] && [ "$ALLOW_DIRECT_UNATTENDED" = "true" ]; then
    tree_is_clean || die "direct unattended execution requires a clean working tree"
  fi
}

run_child_with_timeouts() {
  local events_file="$1"
  local stdout_file="$2"
  local timeout_seconds="$3"
  local idle_seconds="$4"
  shift 4
  python3 - "$events_file" "$stdout_file" "$timeout_seconds" "$idle_seconds" "$@" <<'PY'
import json
import os
import queue
import subprocess
import sys
import threading
import time

events_file, stdout_file, timeout_s, idle_s, *argv = sys.argv[1:]
timeout_s = int(timeout_s)
idle_s = int(idle_s)
start = time.time()
last_output = start
q = queue.Queue()

proc = subprocess.Popen(
    argv,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    bufsize=1,
)

def reader():
    assert proc.stdout is not None
    for line in proc.stdout:
        q.put(line)

threading.Thread(target=reader, daemon=True).start()

timed_out = False
idle_timed_out = False
with open(events_file, "w", encoding="utf-8") as events, open(stdout_file, "w", encoding="utf-8") as out:
    events.write(json.dumps({"event": "start", "argv": argv, "time": start}) + "\n")
    while True:
        try:
            line = q.get(timeout=0.2)
            last_output = time.time()
            out.write(line)
            out.flush()
            events.write(json.dumps({"event": "output", "time": last_output, "line": line.rstrip("\n")}) + "\n")
            events.flush()
        except queue.Empty:
            pass

        now = time.time()
        if proc.poll() is not None:
            break
        if timeout_s > 0 and now - start > timeout_s:
            timed_out = True
            proc.kill()
            break
        if idle_s > 0 and now - last_output > idle_s:
            idle_timed_out = True
            proc.kill()
            break

    rc = proc.wait()
    while True:
        try:
            line = q.get_nowait()
        except queue.Empty:
            break
        out.write(line)
        events.write(json.dumps({"event": "output", "time": time.time(), "line": line.rstrip("\n")}) + "\n")

    end = time.time()
    if timed_out:
        rc = 124
    elif idle_timed_out:
        rc = 125
    events.write(json.dumps({
        "event": "end",
        "time": end,
        "exit_code": rc,
        "timed_out": timed_out,
        "idle_timed_out": idle_timed_out,
    }) + "\n")

sys.exit(rc)
PY
}

write_summary() {
  local summary_file="$1" argv_file="$2" before_file="$3" after_file="$4" start_time="$5" end_time="$6" exit_code="$7" stop_reason="$8" version="$9" gate_result="${10}"
  python3 - "$summary_file" "$argv_file" "$before_file" "$after_file" "$start_time" "$end_time" "$exit_code" "$stop_reason" "$version" "$gate_result" <<'PY'
import json
import sys

summary_file, argv_file, before_file, after_file, start_time, end_time, exit_code, stop_reason, version, gate_result = sys.argv[1:11]

def lines(path):
    with open(path, encoding="utf-8") as f:
        return [line.rstrip("\n") for line in f]

with open(argv_file, encoding="utf-8") as f:
    argv = json.load(f)

data = {
    "command_argv": argv,
    "cwd": argv[argv.index("-C") + 1] if "-C" in argv else None,
    "codex_version": version,
    "start_time": start_time,
    "end_time": end_time,
    "exit_code": int(exit_code),
    "phase_before": lines(before_file),
    "phase_after": lines(after_file),
    "gate_result": gate_result,
    "stop_reason": stop_reason,
}
with open(summary_file, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
}

run_one_chunk() {
  local run_dir="$1" chunk_number="$2"
  local chunk_label chunk_prefix events_file stdout_file last_message summary_file before_file after_file argv_file version start_time end_time exit_code stop_reason timeout_seconds idle_seconds child_prompt chunk_tracking_id tracking report plan_path shared_wt shared_branch shared_plan_path shared_report
  chunk_label=$(printf 'chunk-%03d' "$chunk_number")
  chunk_prefix="$run_dir/$chunk_label"
  events_file="$chunk_prefix.events.jsonl"
  stdout_file="$chunk_prefix.stdout.txt"
  last_message="$chunk_prefix.last-message.txt"
  summary_file="$chunk_prefix.summary.json"
  before_file="$chunk_prefix.before-state.txt"
  after_file="$chunk_prefix.after-state.txt"
  argv_file="$chunk_prefix.argv.json"
  version=$(codex_version)
  start_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  chunk_tracking_id=$(date -u +%Y%m%dT%H%M%SZ)
  tracking=$(tracking_dir "$REPO_ROOT" "$PIPELINE_ID")
  report=$(report_path "$REPO_ROOT" "$PLAN_REPORT_SLUG")
  plan_path=$(resolve_plan_path "$REPO_ROOT" "$PLAN")
  shared_wt=$(shared_worktree_path)
  shared_branch=$(shared_worktree_branch)
  shared_plan_path=$(resolve_plan_path "$shared_wt" "$PLAN")
  shared_report=$(report_path "$shared_wt" "$PLAN_REPORT_SLUG")

  mkdir -p "$tracking"
  collect_state_file "$before_file"
  child_prompt=$(cat <<EOF
run-plan $PLAN finish auto

RUNNER-MANAGED CHUNK: You are running under zskills-runner.sh. Do not invoke zskills-runner.sh again. Execute exactly one incomplete phase, then stop after writing the required report, tracking markers, and landing evidence appropriate for this chunk.

External ZSkills runner contract for this chunk:
- Execute exactly one incomplete phase from $PLAN, then stop.
- Repository root: $REPO_ROOT
- Plan path: $plan_path
- Report path: $report
- Pipeline id: $PIPELINE_ID
- Resolved landing mode: $EXECUTION_LANDING. You must use this mode for this chunk.
- Execution base branch: $BASE_BRANCH
- Execution remote: $REMOTE
- Shared finish-auto worktree path: $shared_wt
- Shared finish-auto branch: $shared_branch
- Shared finish-auto plan path: $shared_plan_path
- Shared finish-auto report path: $shared_report
- Canonical tracking directory: $tracking
- Tracking id: if $tracking contains a handoff.run-plan.* marker, reuse the newest marker suffix; otherwise use $chunk_tracking_id.
- Write canonical marker files directly in the canonical tracking directory, with no timestamp or phase subdirectories, even if implementation happens in a git worktree:
  - requires.verify-changes.<tracking-id>
  - step.run-plan.<tracking-id>.implement
  - step.run-plan.<tracking-id>.verify
  - step.run-plan.<tracking-id>.report
  - step.verify-changes.<tracking-id>.tests-run
  - step.verify-changes.<tracking-id>.complete
  - fulfilled.verify-changes.<tracking-id>
  - if another phase remains: handoff.run-plan.<tracking-id>; do not leave step.run-plan.<tracking-id>.land or fulfilled.run-plan.<tracking-id> present for this tracking id
  - if the plan is complete: step.run-plan.<tracking-id>.land and fulfilled.run-plan.<tracking-id>; remove any stale handoff.run-plan.<tracking-id>
- The report must include a "## Phase" heading, a "Status:" line, tests run, verification result, landing result, remaining phases, and a scope assessment.
- Mark completed progress tracker rows with exactly "✅ Done" so runner status parsing stays stable.
- If resolved landing mode is direct, finalize source changes, plan tracker updates, and the report, then commit the scoped files directly on the current branch before exiting. Leave no dirty project artifacts except ignored .zskills tracking/log state.
- If resolved landing mode is cherry-pick, create/use the shared finish-auto worktree and branch above. Finalize source changes, plan tracker updates, and the report in that shared worktree, then commit the chunk there. If another phase remains, do not cherry-pick or land to $BASE_BRANCH yet; leave a handoff marker and keep the shared worktree clean for the next chunk. If the plan is complete, run final cross-phase verification, then land the accumulated shared-worktree commits to $BASE_BRANCH in the main repo and write final land/fulfilled markers.
- If resolved landing mode is pr, create/use the shared finish-auto worktree and branch above. Finalize source changes, plan tracker updates, and the report in that shared worktree, then commit the chunk there. Push/create or update the PR only when the plan is complete unless the user explicitly asked for earlier PR updates. Do not push directly to the base branch.
- Do not claim in the report that work was committed, cherry-picked, pushed, or fully landed until that git operation has actually succeeded. Before landing, use pending language; after landing, update the report with the real landed state.
- For non-final chunks, the durable plan/report state is expected in the shared finish-auto worktree, not the main repository. For final chunks, ensure the main repository has the landed plan/report updates and canonical markers before exiting.
- Do not commit .zskills tracking files.
EOF
)
  CHILD_CODEX_ARGV=("$CODEX_BIN" "exec" "-C" "$REPO_ROOT" "--add-dir" "/tmp" "--sandbox" "$SANDBOX" "-c" "approval_policy=\"$APPROVAL_POLICY\"" "--json" "-o" "$last_message")
  CHILD_CODEX_ARGV+=("${EXTRA_CODEX_ARGS[@]}" "$child_prompt")
  python3 - "$argv_file" "${CHILD_CODEX_ARGV[@]}" <<'PY'
import json, sys
with open(sys.argv[1], "w", encoding="utf-8") as f:
    json.dump(sys.argv[2:], f)
PY

  printf '{"event":"runner-start","chunk":%s,"time":"%s"}\n' "$chunk_number" "$start_time" >> "$run_dir/runner.jsonl"
  timeout_seconds="${ZSKILLS_RUNNER_TIMEOUT_SECONDS:-$((CHUNK_TIMEOUT_MINUTES * 60))}"
  idle_seconds="${ZSKILLS_RUNNER_IDLE_TIMEOUT_SECONDS:-$((IDLE_TIMEOUT_MINUTES * 60))}"
  set +e
  run_child_with_timeouts "$events_file" "$stdout_file" "$timeout_seconds" "$idle_seconds" "${CHILD_CODEX_ARGV[@]}"
  exit_code=$?
  set -e
  end_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  collect_state_file "$after_file"
  case "$exit_code" in
    0) stop_reason="chunk-exit-0" ;;
    124) stop_reason="chunk-timeout" ;;
    125) stop_reason="chunk-idle-timeout" ;;
    *) stop_reason="chunk-exit-$exit_code" ;;
  esac
  write_summary "$summary_file" "$argv_file" "$before_file" "$after_file" "$start_time" "$end_time" "$exit_code" "$stop_reason" "$version" "not-run-phase-4"
  printf '{"event":"runner-end","chunk":%s,"time":"%s","exit_code":%s,"stop_reason":"%s"}\n' "$chunk_number" "$end_time" "$exit_code" "$stop_reason" >> "$run_dir/runner.jsonl"
  LAST_RUN_DIR="$run_dir"
  LAST_SUMMARY_FILE="$summary_file"
  LAST_BEFORE_FILE="$before_file"
  LAST_AFTER_FILE="$after_file"
  LAST_CHUNK_LABEL="$chunk_label"
  echo "run_dir=$run_dir"
  echo "summary_file=$summary_file"
  return "$exit_code"
}

run_chunks() {
  local log_root run_dir chunk chunk_status
  log_root=$(abs_runner_path "$LOG_DIR")
  run_dir="$log_root/run-plan-$PLAN_KEY-$(date -u +%Y%m%dT%H%M%SZ)"
  mkdir -p "$run_dir"
  chunk=1
  while [ "$chunk" -le "$MAX_CHUNKS" ]; do
    set +e
    run_one_chunk "$run_dir" "$chunk"
    chunk_status=$?
    set -e
    [ "$chunk_status" -eq 0 ] || exit "$chunk_status"
    validate_chunk_progress "$LAST_RUN_DIR" "$LAST_SUMMARY_FILE" "$LAST_BEFORE_FILE" "$LAST_AFTER_FILE" "$LAST_CHUNK_LABEL"
    if plan_is_complete "$LAST_AFTER_FILE"; then
      runner_stop_reason "$LAST_SUMMARY_FILE" "complete"
      echo "runner_stop_reason=complete"
      return 0
    fi
    chunk=$((chunk + 1))
  done
  runner_stop_reason "$LAST_SUMMARY_FILE" "max-chunks"
  echo "runner_stop_reason=max-chunks" >&2
  return 30
}

MODE=""
PLAN=""
REPO="."
DRY_RUN=0
MAX_CHUNKS=""
CHUNK_TIMEOUT_MINUTES=""
IDLE_TIMEOUT_MINUTES=""
LOG_DIR=""
STOP_MARKER=""
SANDBOX=""
APPROVAL_POLICY=""
EXECUTION_LANDING=""
ALLOW_DIRECT_UNATTENDED=""
BASE_BRANCH=""
REMOTE=""
CODEX_BIN="${CODEX_BIN:-codex}"
EXTRA_CODEX_ARGS=()
LOCK_DIR=""
LAST_RUN_DIR=""
LAST_SUMMARY_FILE=""
LAST_BEFORE_FILE=""
LAST_AFTER_FILE=""
LAST_CHUNK_LABEL=""

if [ $# -eq 0 ]; then
  usage
  exit 2
fi

case "$1" in
  -h|--help)
    usage
    exit 0
    ;;
  status|stop|run-plan)
    MODE="$1"
    shift
    ;;
  *)
    die "unknown command '$1'"
    ;;
esac

case "$MODE" in
  status|stop)
    [ $# -gt 0 ] || die "$MODE requires a plan"
    PLAN="$1"
    shift
    ;;
  run-plan)
    [ $# -ge 3 ] || die "run-plan requires: <plan> finish auto"
    PLAN="$1"
    [ "$2" = "finish" ] || die "only run-plan <plan> finish auto is supported"
    [ "$3" = "auto" ] || die "only run-plan <plan> finish auto is supported"
    shift 3
    ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --max-chunks) MAX_CHUNKS="$2"; shift 2 ;;
    --chunk-timeout-min) CHUNK_TIMEOUT_MINUTES="$2"; shift 2 ;;
    --idle-timeout-min) IDLE_TIMEOUT_MINUTES="$2"; shift 2 ;;
    --log-dir) LOG_DIR="$2"; shift 2 ;;
    --stop-marker) STOP_MARKER="$2"; shift 2 ;;
    --sandbox) SANDBOX="$2"; shift 2 ;;
    --approval-policy) APPROVAL_POLICY="$2"; shift 2 ;;
    --allow-direct-unattended) ALLOW_DIRECT_UNATTENDED=true; shift ;;
    --codex-bin) CODEX_BIN="$2"; shift 2 ;;
    --codex-arg) EXTRA_CODEX_ARGS+=("$2"); shift 2 ;;
    --dangerously-bypass-approvals-and-sandbox)
      die "dangerous bypass is refused by zskills-runner"
      ;;
    *) die "unknown option '$1'" ;;
  esac
done

if ! REPO_ROOT=$(git_repo_root "$REPO"); then
  die "repo is not a git worktree: $REPO"
fi
CONFIG_FILE=$(find_config "$REPO_ROOT")
PLAN_SLUG=$(plan_slug "$PLAN")
PLAN_KEY=$(plan_key "$PLAN")
PLAN_REPORT_SLUG=$(plan_report_slug "$PLAN")
PIPELINE_ID="run-plan.$PLAN_KEY"

[ -n "$MAX_CHUNKS" ] || MAX_CHUNKS=$(json_get "$CONFIG_FILE" "runner.max_chunks" "10")
[ -n "$CHUNK_TIMEOUT_MINUTES" ] || CHUNK_TIMEOUT_MINUTES=$(json_get "$CONFIG_FILE" "runner.chunk_timeout_minutes" "90")
[ -n "$IDLE_TIMEOUT_MINUTES" ] || IDLE_TIMEOUT_MINUTES=$(json_get "$CONFIG_FILE" "runner.idle_timeout_minutes" "15")
[ -n "$LOG_DIR" ] || LOG_DIR=$(json_get "$CONFIG_FILE" "runner.log_dir" ".zskills/logs")
[ -n "$STOP_MARKER" ] || STOP_MARKER=$(json_get "$CONFIG_FILE" "runner.stop_marker" ".zskills/stop")
[ -n "$SANDBOX" ] || SANDBOX=$(json_get "$CONFIG_FILE" "runner.sandbox" "workspace-write")
[ -n "$APPROVAL_POLICY" ] || APPROVAL_POLICY=$(json_get "$CONFIG_FILE" "runner.approval_policy" "never")
[ -n "$EXECUTION_LANDING" ] || EXECUTION_LANDING=$(json_get "$CONFIG_FILE" "execution.landing" "cherry-pick")
[ -n "$ALLOW_DIRECT_UNATTENDED" ] || ALLOW_DIRECT_UNATTENDED=$(json_get "$CONFIG_FILE" "runner.allow_direct_unattended" "false")
[ -n "$BASE_BRANCH" ] || BASE_BRANCH=$(json_get "$CONFIG_FILE" "execution.base_branch" "main")
[ -n "$REMOTE" ] || REMOTE=$(json_get "$CONFIG_FILE" "execution.remote" "origin")
[ -n "${BRANCH_PREFIX:-}" ] || BRANCH_PREFIX=$(json_get "$CONFIG_FILE" "execution.branch_prefix" "run-plan/")

case "$SANDBOX" in
  read-only|workspace-write|danger-full-access) ;;
  *) die "unsupported sandbox '$SANDBOX'" ;;
esac
case "$APPROVAL_POLICY" in
  never|on-request|untrusted) ;;
  *) die "unsupported approval policy '$APPROVAL_POLICY'" ;;
esac

contains_dangerous_arg "${EXTRA_CODEX_ARGS[@]}" && die "dangerous bypass is refused by zskills-runner"

if ! command -v "$CODEX_BIN" >/dev/null 2>&1; then
  die "codex executable not found: $CODEX_BIN"
fi

CODEX_ARGV=("$CODEX_BIN" "exec" "-C" "$REPO_ROOT" "--add-dir" "/tmp" "--sandbox" "$SANDBOX" "-c" "approval_policy=\"$APPROVAL_POLICY\"")
if [ "$MODE" = "run-plan" ]; then
  CODEX_ARGV+=("${EXTRA_CODEX_ARGS[@]}" "run-plan $PLAN finish auto")
fi

case "$MODE" in
  status)
    print_resolved
    if [ -f "$REPO_ROOT/$STOP_MARKER" ]; then
      echo "stop_marker_present=true"
    else
      echo "stop_marker_present=false"
    fi
    ;;
  stop)
    mkdir -p "$(dirname "$REPO_ROOT/$STOP_MARKER")"
    printf 'plan=%s\nstopped_at=%s\n' "$PLAN" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$REPO_ROOT/$STOP_MARKER"
    echo "stop marker written: $REPO_ROOT/$STOP_MARKER"
    ;;
  run-plan)
    if [ "$DRY_RUN" -eq 1 ]; then
      print_resolved
      exit 0
    fi
    acquire_lock
    preflight
    print_resolved
    write_initial_state
    run_chunks
    ;;
esac
