#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"

usage() {
  cat <<'EOF'
Usage: scripts/install.sh [--codex-home <path>] [--project <path>] [--no-project-config]

Installs this Codex Z Skills distribution into CODEX_HOME.
It does not write skills or support assets into the current project repo.
By default it also initializes .codex/zskills-config.json in the current
project if that file does not already exist.
EOF
}

PROJECT_PATH="${ZSKILLS_PROJECT_PATH:-}"
WRITE_PROJECT_CONFIG=1

while [ $# -gt 0 ]; do
  case "$1" in
    --codex-home)
      CODEX_HOME="$2"
      shift 2
      ;;
    --project)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --no-project-config)
      WRITE_PROJECT_CONFIG=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument '$1'" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[ -d "$ROOT/skills" ] || { echo "ERROR: missing $ROOT/skills" >&2; exit 1; }
[ -d "$ROOT/zskills-support" ] || { echo "ERROR: missing $ROOT/zskills-support" >&2; exit 1; }

mkdir -p "$CODEX_HOME/skills" "$CODEX_HOME/zskills-support"

install_skill_dirs() {
  local src_dir dst_dir name
  src_dir="$ROOT/skills"
  dst_dir="$CODEX_HOME/skills"
  mkdir -p "$dst_dir"
  for skill_path in "$src_dir"/*; do
    [ -d "$skill_path" ] || continue
    name=$(basename "$skill_path")
    rm -rf "$dst_dir/$name"
    cp -R "$skill_path" "$dst_dir/$name"
  done
}

if command -v rsync >/dev/null 2>&1; then
  install_skill_dirs
  rsync -a --delete "$ROOT/zskills-support/" "$CODEX_HOME/zskills-support/"
else
  install_skill_dirs
  rm -rf "$CODEX_HOME/zskills-support"
  mkdir -p "$CODEX_HOME"
  cp -R "$ROOT/zskills-support" "$CODEX_HOME/zskills-support"
fi

python3 - "$CODEX_HOME" <<'PY'
from pathlib import Path
import sys

codex_home = sys.argv[1].rstrip("/")
roots = [Path(codex_home) / "skills", Path(codex_home) / "zskills-support"]
for root in roots:
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        try:
            data = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        updated = data.replace("/home/vscode/.codex", codex_home)
        if updated != data:
            path.write_text(updated, encoding="utf-8")
PY

resolve_project_root() {
  local candidate="$1"
  if [ -n "$candidate" ]; then
    (cd "$candidate" && pwd)
    return
  fi
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    git rev-parse --show-toplevel
  else
    pwd
  fi
}

write_project_config() {
  local project_root config_file
  project_root=$(resolve_project_root "$PROJECT_PATH")
  config_file="$project_root/.codex/zskills-config.json"
  mkdir -p "$project_root/.codex"
  if [ -e "$config_file" ]; then
    echo "Project config already exists: $config_file"
    return
  fi
  cat > "$config_file" <<'JSON'
{
  "execution": {
    "landing": "cherry-pick",
    "base_branch": "main",
    "remote": "origin",
    "main_protected": false,
    "branch_prefix": "zskills/"
  },
  "runner": {
    "max_chunks": 10,
    "chunk_timeout_minutes": 90,
    "idle_timeout_minutes": 15,
    "log_dir": ".zskills/logs",
    "stop_marker": ".zskills/stop",
    "sandbox": "workspace-write",
    "approval_policy": "never",
    "allow_direct_unattended": false
  }
}
JSON
  echo "Initialized project config: $config_file"
}

if [ "$WRITE_PROJECT_CONFIG" = "1" ]; then
  write_project_config
fi

echo "Installed Z Skills for Codex into $CODEX_HOME"
echo "Installed Z Skills: $(find "$ROOT/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
echo "Restart Codex if you need updated skill metadata to be discovered."
