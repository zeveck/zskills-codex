#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
MODE="${1:---quick}"
REPORT_DIR="${ZSKILLS_CANARY_REPORT_DIR:-$ROOT/.zskills/canary-reports}"
REPORT="${ZSKILLS_CANARY_REPORT:-$REPORT_DIR/canary-zskills-codex.md}"
CODEX_HOME_CANARY="${ZSKILLS_CANARY_CODEX_HOME:-${CODEX_HOME:-$HOME/.codex}}"
CANARY_SANDBOX="${ZSKILLS_CANARY_SANDBOX:-danger-full-access}"
CANARY_MODEL="${ZSKILLS_CANARY_MODEL:-gpt-5.4-mini}"

usage() {
  cat <<'EOF'
Usage:
  scripts/canary-zskills-codex.sh --quick
  scripts/canary-zskills-codex.sh --runner
  scripts/canary-zskills-codex.sh --all

Runs disposable local canaries for the Codex Z Skills distribution.
Set ZSKILLS_CANARY_SANDBOX and ZSKILLS_CANARY_MODEL to override runner defaults.
Set ZSKILLS_CANARY_REPORT or ZSKILLS_CANARY_REPORT_DIR to choose the report path.
By default reports are written under ignored .zskills/canary-reports.
EOF
}

log() {
  printf '%s\n' "$*"
}

append_report() {
  printf '%s\n' "$*" >> "$REPORT"
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

start_report() {
  mkdir -p "$REPORT_DIR"
  mkdir -p "$(dirname "$REPORT")"
  {
    echo "# ZSkills Codex Canary Report"
    echo
    echo "- Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "- Repo: $ROOT"
    echo "- Mode: $MODE"
    echo "- Sandbox: $CANARY_SANDBOX"
    echo "- Model: $CANARY_MODEL"
    echo
  } > "$REPORT"
}

run_step() {
  local name="$1"
  shift
  log "==> $name"
  append_report "## $name"
  append_report
  append_report '```text'
  if "$@" >> "$REPORT" 2>&1; then
    append_report '```'
    append_report
    append_report "Result: PASS"
    append_report
  else
    local rc=$?
    append_report '```'
    append_report
    append_report "Result: FAIL (exit $rc)"
    append_report
    return "$rc"
  fi
}

skill_names() {
  find "$ROOT/skills" -mindepth 2 -maxdepth 2 -name SKILL.md \
    | sed "s#^$ROOT/skills/##; s#/SKILL.md##" \
    | sort
}

quick_invariants() {
  cd "$ROOT"

  local count
  count=$(skill_names | wc -l | tr -d ' ')
  [ "$count" = "22" ] || fail "expected 22 installable skills, found $count"
  echo "skill_count=$count"

  ! skill_names | grep -qx 'zskills-codex' || fail "zskills-codex must not be installable"
  ! skill_names | grep -qx 'social-seo' || fail "social-seo must not be installable"
  [ ! -e "$ROOT/.claude" ] || fail ".claude must not exist in Codex-only distribution"
  ! rg -n 'social-seo|social seo|Social SEO' "$ROOT/skills" "$ROOT/zskills-support" "$ROOT/README.md" || fail "social-seo reference found in distribution content"

python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
errors = []
runtime_blocks = {}
required_subagent_rule = (
    "Use sub-agents only when the user explicitly asks for agents, parallel work, "
    "or delegation, or when the user explicitly invokes a Z Skill step whose "
    "workflow requires an independent reviewer, devil's-advocate critique, or "
    "fresh verification context."
)
retired_subagent_rule = (
    "Use sub-agents only when the user explicitly asks for agents, parallel work, "
    "or delegation. For Z Skills landing gates"
)
for skill in sorted((root / "skills").iterdir()):
    md = skill / "SKILL.md"
    if not md.exists():
        errors.append(f"{skill.name}: missing SKILL.md")
        continue
    text = md.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        errors.append(f"{skill.name}: missing frontmatter")
        continue
    end = text.find("\n---\n", 4)
    if end == -1:
        errors.append(f"{skill.name}: unterminated frontmatter")
        continue
    front = text[4:end]
    keys = [line.split(":", 1)[0] for line in front.splitlines() if ":" in line and not line.startswith(" ")]
    if keys != ["name", "description"]:
        errors.append(f"{skill.name}: frontmatter keys are {keys}, expected name/description")
    if f"name: {skill.name}" not in front:
        errors.append(f"{skill.name}: name does not match directory")
    if "allowed-tools:" in front or "tools:" in front:
        errors.append(f"{skill.name}: Claude-style tool frontmatter present")
    ref = skill / "references" / "upstream-claude-adapted.md"
    if not ref.exists():
        errors.append(f"{skill.name}: missing upstream adapted reference")
    start = text.find("Use Codex behavior first:\n")
    end = text.find("\nDetailed upstream text", start)
    if start == -1 or end == -1:
        errors.append(f"{skill.name}: missing shared Codex runtime block")
    else:
        block = text[start:end]
        runtime_blocks.setdefault(block, []).append(skill.name)
        if required_subagent_rule not in block:
            errors.append(f"{skill.name}: missing bounded skill-required sub-agent rule")
        if retired_subagent_rule in block:
            errors.append(f"{skill.name}: retired narrower sub-agent rule is still present")
    installed_md = root / ".agents" / "skills" / skill.name / "SKILL.md"
    if not installed_md.exists():
        errors.append(f"{skill.name}: missing installed .agents SKILL.md")
    elif installed_md.read_text(encoding="utf-8") != text:
        errors.append(f"{skill.name}: source and .agents SKILL.md differ")

if len(runtime_blocks) != 1:
    details = []
    for block, names in runtime_blocks.items():
        preview = " ".join(block.split())[:120]
        details.append(f"{len(names)} skill(s): {', '.join(names)} :: {preview}")
    errors.append("shared Codex runtime blocks drifted:\n" + "\n".join(details))

support = root / "zskills-support"
for rel in [
    "scripts/zskills-runner.sh",
    "scripts/zskills-gate.sh",
    "scripts/post-run-invariants.sh",
    "scripts/worktree-add-safe.sh",
    "config/zskills-config.schema.json",
]:
    if not (support / rel).exists():
        errors.append(f"support missing {rel}")

if errors:
    print("\n".join(errors))
    raise SystemExit(1)
print("frontmatter_and_references=ok")
print("shared_runtime_rules=ok")
print("source_installed_skill_wrappers=ok")
PY
}

install_preserves_unrelated() {
  local tmp total
  tmp=$(mktemp -d)
  mkdir -p "$tmp/codex-home/skills/existing" "$tmp/codex-home/skills/run-plan" "$tmp/project"
  git -C "$tmp/project" init -q

  bash "$ROOT/scripts/install.sh" --project "$tmp/project"
  [ -f "$tmp/project/.agents/skills/run-plan/SKILL.md" ] || fail "project-local run-plan was not installed"
  [ -f "$tmp/project/.agents/zskills-support/scripts/zskills-runner.sh" ] || fail "project-local support was not installed"
  [ -f "$tmp/project/.agents/zskills-config.json" ] || fail "project config was not initialized"
  ! rg -n '/home/vscode/.codex' "$tmp/project/.agents/skills" "$tmp/project/.agents/zskills-support"

  printf '%s\n' '---' 'name: existing' 'description: keep me' '---' > "$tmp/codex-home/skills/existing/SKILL.md"
  printf old > "$tmp/codex-home/skills/run-plan/OLD"
  bash "$ROOT/scripts/install.sh" --codex-home "$tmp/codex-home" --project "$tmp/project"
  [ -f "$tmp/codex-home/skills/existing/SKILL.md" ] || fail "unrelated skill was removed"
  [ ! -e "$tmp/codex-home/skills/run-plan/OLD" ] || fail "owned stale skill file survived"
  [ -f "$tmp/codex-home/skills/run-plan/SKILL.md" ] || fail "run-plan was not installed"
  python3 - "$tmp/project/.agents/zskills-config.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["execution"]["landing"] == "cherry-pick"
assert data["runner"]["allow_direct_unattended"] is False
PY
  python3 - "$tmp/project/.agents/zskills-config.json" <<'PY'
import json, sys
p = sys.argv[1]
data = json.load(open(p))
data["execution"]["landing"] = "pr"
json.dump(data, open(p, "w"))
PY
  bash "$ROOT/scripts/install.sh" --codex-home "$tmp/codex-home" --project "$tmp/project"
  python3 - "$tmp/project/.agents/zskills-config.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["execution"]["landing"] == "pr"
PY
  ! rg -n '/home/vscode/.codex' "$tmp/codex-home/skills" "$tmp/codex-home/zskills-support"
  total=$(find "$tmp/codex-home/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')
  echo "total_skill_dirs_after_install=$total"
  rm -rf "$tmp"
}

script_checks() {
  cd "$ROOT"
  for f in zskills-support/scripts/{zskills-runner.sh,zskills-gate.sh,post-run-invariants.sh,land-phase.sh,worktree-add-safe.sh,clear-tracking.sh} scripts/install.sh scripts/canary-zskills-codex.sh; do
    bash -n "$f"
  done
  python3 -m json.tool zskills-support/config/zskills-config.schema.json >/dev/null
  zskills-support/tests/runner/run.sh all
  zskills-support/tests/runner/run.sh fake-timeout
  zskills-support/tests/runner/run.sh fake-idle-timeout
}

setup_temp_codex_home() {
  bash "$ROOT/scripts/install.sh" --codex-home "$CODEX_HOME_CANARY" --no-project-config >/dev/null
  echo "$CODEX_HOME_CANARY"
}

runner_extra_args() {
  if [ -n "$CANARY_MODEL" ]; then
    printf '%s\n' --codex-arg -m --codex-arg "$CANARY_MODEL"
  fi
}

make_direct_repo() {
  local repo="$1"
  git -C "$repo" init -q -b main
  git -C "$repo" config user.email canary@example.test
  git -C "$repo" config user.name "ZSkills Canary"
  mkdir -p "$repo/plans" "$repo/.agents" "$repo/scripts"
  printf 'phase-0: seed\n' > "$repo/counter.txt"
  cat > "$repo/scripts/test.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
from pathlib import Path
lines = Path("counter.txt").read_text().splitlines()
allowed = [
    ["phase-0: seed"],
    ["phase-0: seed", "phase-1: alpha"],
    ["phase-0: seed", "phase-1: alpha", "phase-2: beta"],
]
if lines not in allowed:
    raise SystemExit(f"unexpected counter state: {lines!r}")
PY
EOF
  chmod +x "$repo/scripts/test.sh"
  printf '.zskills/\n.test-results.txt\n' > "$repo/.gitignore"
  cat > "$repo/.agents/zskills-config.json" <<EOF
{
  "execution": {"landing": "direct", "main_protected": false, "base_branch": "main", "remote": "origin"},
  "testing": {"unit_cmd": "bash scripts/test.sh", "full_cmd": "bash scripts/test.sh", "output_file": ".test-results.txt", "file_patterns": ["counter.txt", "scripts/test.sh"]},
  "runner": {"allow_direct_unattended": true, "max_chunks": 4, "chunk_timeout_minutes": 20, "idle_timeout_minutes": 8, "log_dir": ".zskills/logs", "stop_marker": ".zskills/stop", "sandbox": "$CANARY_SANDBOX", "approval_policy": "never"}
}
EOF
  cat > "$repo/plans/direct-canary.md" <<'EOF'
# Direct Runner Canary

## Progress Tracker

| Phase | Status | Notes |
| --- | --- | --- |
| 1. Add alpha line | ⬜ Not Started | Append exactly `phase-1: alpha` to `counter.txt`. Do not add phase 2 in this phase. Run `bash scripts/test.sh`. |
| 2. Add beta line | ⬜ Not Started | Append exactly `phase-2: beta` to `counter.txt`. Run `bash scripts/test.sh`. |

## Acceptance Criteria

- `counter.txt` contains exactly `phase-0: seed`, `phase-1: alpha`, `phase-2: beta` by the end.
- `bash scripts/test.sh` passes after each phase.
- Each phase updates this tracker and `reports/plan-direct-canary.md`.
- Standard ZSkills tracking markers are written and the report includes a scope assessment.
EOF
  git -C "$repo" add .
  git -C "$repo" commit -q -m init
}

run_direct_canary() {
  local repo codex_home
  repo=$(mktemp -d /tmp/zskills-codex-canary-direct.XXXXXX)
  codex_home=$(setup_temp_codex_home)
  make_direct_repo "$repo"
  echo "repo=$repo"
  echo "codex_home=$codex_home"
  CODEX_HOME="$codex_home" "$codex_home/zskills-support/scripts/zskills-runner.sh" \
    run-plan plans/direct-canary.md finish auto \
    --repo "$repo" \
    --max-chunks 4 \
    --chunk-timeout-min 20 \
    --idle-timeout-min 8 \
    --sandbox "$CANARY_SANDBOX" \
    $(runner_extra_args) || return
  (cd "$repo" && bash scripts/test.sh) || return
  git -C "$repo" status --short --branch || return
  git -C "$repo" log --oneline --max-count=4 || return
  cat "$repo/counter.txt" || return
}

make_cherry_repo() {
  local repo="$1" origin="$2"
  git -C "$origin" init -q --bare
  git -C "$repo" init -q -b main
  git -C "$repo" config user.email canary@example.test
  git -C "$repo" config user.name "ZSkills Canary"
  git -C "$repo" remote add origin "$origin"
  mkdir -p "$repo/plans" "$repo/.agents" "$repo/scripts"
  printf 'base\n' > "$repo/value.txt"
  cat > "$repo/scripts/test.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
grep -qx 'base' value.txt
grep -qx 'cherry-pick-canary' value.txt
EOF
  chmod +x "$repo/scripts/test.sh"
  printf '.zskills/\n.test-results.txt\n' > "$repo/.gitignore"
  cat > "$repo/.agents/zskills-config.json" <<EOF
{
  "execution": {"landing": "cherry-pick", "main_protected": false, "base_branch": "main", "remote": "origin", "branch_prefix": "zskills-canary/"},
  "testing": {"unit_cmd": "bash scripts/test.sh", "full_cmd": "bash scripts/test.sh", "output_file": ".test-results.txt", "file_patterns": ["value.txt", "scripts/test.sh"]},
  "runner": {"max_chunks": 2, "chunk_timeout_minutes": 20, "idle_timeout_minutes": 8, "log_dir": ".zskills/logs", "stop_marker": ".zskills/stop", "sandbox": "$CANARY_SANDBOX", "approval_policy": "never"}
}
EOF
  cat > "$repo/plans/cherry-canary.md" <<'EOF'
# Cherry Pick Runner Canary

## Progress Tracker

| Phase | Status | Notes |
| --- | --- | --- |
| 1. Add cherry-pick marker | ⬜ Not Started | Append exactly `cherry-pick-canary` as a second line in `value.txt`. Run `bash scripts/test.sh`. Land via cherry-pick mode, not direct mode. |

## Acceptance Criteria

- `value.txt` contains exactly `base` then `cherry-pick-canary`.
- `bash scripts/test.sh` passes.
- The plan and `reports/plan-cherry-canary.md` are updated.
- Standard ZSkills tracking markers are written and the report includes a scope assessment.
EOF
  git -C "$repo" add .
  git -C "$repo" commit -q -m init
  git -C "$repo" push -q -u origin main
}

run_cherry_canary() {
  local repo origin codex_home
  repo=$(mktemp -d /tmp/zskills-codex-canary-cp.XXXXXX)
  origin=$(mktemp -d /tmp/zskills-codex-canary-origin.XXXXXX)
  codex_home=$(setup_temp_codex_home)
  make_cherry_repo "$repo" "$origin"
  echo "repo=$repo"
  echo "origin=$origin"
  echo "codex_home=$codex_home"
  CODEX_HOME="$codex_home" "$codex_home/zskills-support/scripts/zskills-runner.sh" \
    run-plan plans/cherry-canary.md finish auto \
    --repo "$repo" \
    --max-chunks 2 \
    --chunk-timeout-min 20 \
    --idle-timeout-min 8 \
    --sandbox "$CANARY_SANDBOX" \
    $(runner_extra_args) || return
  (cd "$repo" && bash scripts/test.sh) || return
  git -C "$repo" status --short --branch || return
  git -C "$repo" log --oneline --max-count=4 || return
  find "$repo/.zskills/tracking" -type f -printf '%P\n' | sort || return
}

skill_coverage_table() {
  cat <<'EOF'
Skill coverage classification:
- add-block: static wrapper/reference coverage; full block app canary deferred to a real block-diagram repo.
- add-example: static wrapper/reference coverage; full block app canary deferred to a real block-diagram repo.
- briefing: covered by metadata/reference checks; real repo status behavior is low-risk read-only.
- commit: partially covered by direct/cherry canary commit behavior; standalone selective-commit canary still useful.
- do: covered by run-plan child execution path only indirectly; standalone bounded edit canary still useful.
- doc: covered by report/documentation update behavior in runner canaries.
- draft-plan: covered by this plan file creation; full adversarial-agent rounds not exercised by script.
- fix-issues: not yet fully canaried; needs local issue tracker fixture.
- fix-report: not yet fully canaried; needs completed fix-issues fixture.
- investigate: not yet fully canaried; needs seeded bug fixture.
- manual-testing: static wrapper/reference coverage; browser fixture canary deferred.
- model-design: static wrapper/reference coverage; full block-diagram repo deferred.
- plans: covered by plan status/progress parsing in runner canaries.
- playwright-cli: static wrapper/reference coverage; browser fixture canary deferred.
- qe-audit: not yet fully canaried; needs seeded regression fixture.
- refine-plan: not yet fully canaried; needs partially executed plan fixture.
- research-and-go: not fully canaried because it intentionally performs broad autonomous work.
- research-and-plan: partially covered by this canary plan shape; standalone local planning canary still useful.
- review-feedback: not yet fully canaried; needs product feedback JSON fixture.
- run-plan: covered by real direct and cherry-pick runner canaries plus fake runner suite.
- update-zskills: static wrapper/reference coverage; upstream update mutation canary deferred.
- verify-changes: covered by runner marker/report verification contract and package verification.
EOF
}

case "$MODE" in
  --quick)
    start_report
    run_step "Package Invariants" quick_invariants
    run_step "Installer Preservation" install_preserves_unrelated
    run_step "Scripted Verification" script_checks
    run_step "Skill Coverage Table" skill_coverage_table
    log "report=$REPORT"
    ;;
  --runner)
    start_report
    run_step "Direct Runner Canary" run_direct_canary
    run_step "Cherry-Pick Runner Canary" run_cherry_canary
    log "report=$REPORT"
    ;;
  --all)
    start_report
    run_step "Package Invariants" quick_invariants
    run_step "Installer Preservation" install_preserves_unrelated
    run_step "Scripted Verification" script_checks
    run_step "Direct Runner Canary" run_direct_canary
    run_step "Cherry-Pick Runner Canary" run_cherry_canary
    run_step "Skill Coverage Table" skill_coverage_table
    log "report=$REPORT"
    ;;
  -h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
