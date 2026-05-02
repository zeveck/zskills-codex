#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"

usage() {
  cat <<'EOF'
Usage: scripts/install.sh [--project <path>] [--global] [--codex-home <path>] [--no-project-config]

Installs this Codex Z Skills distribution into the target project by default:

  .agents/skills/
  .agents/zskills-support/
  .agents/zskills-config.json

Use --global, or --codex-home <path>, only when you explicitly want a
user-level install under CODEX_HOME.
EOF
}

PROJECT_PATH="${ZSKILLS_PROJECT_PATH:-}"
WRITE_PROJECT_CONFIG=1
INSTALL_GLOBAL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --global)
      INSTALL_GLOBAL=1
      shift
      ;;
    --codex-home)
      CODEX_HOME="$2"
      INSTALL_GLOBAL=1
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

PROJECT_ROOT=$(resolve_project_root "$PROJECT_PATH")

install_skill_dirs() {
  local dst_dir="$1"
  local src_dir name
  src_dir="$ROOT/skills"
  mkdir -p "$dst_dir"
  for skill_path in "$src_dir"/*; do
    [ -d "$skill_path" ] || continue
    name=$(basename "$skill_path")
    rm -rf "$dst_dir/$name"
    cp -R "$skill_path" "$dst_dir/$name"
  done
}

install_support_dir() {
  local dst_dir="$1"
  if command -v rsync >/dev/null 2>&1; then
    mkdir -p "$dst_dir"
    rsync -a --delete "$ROOT/zskills-support/" "$dst_dir/"
  else
    rm -rf "$dst_dir"
    mkdir -p "$(dirname "$dst_dir")"
    cp -R "$ROOT/zskills-support" "$dst_dir"
  fi
}

rewrite_installed_paths() {
  local install_root="$1"
  python3 - "$install_root" <<'PY'
from pathlib import Path
import sys

install_root = sys.argv[1].rstrip("/")
roots = [Path(install_root) / "skills", Path(install_root) / "zskills-support"]
for root in roots:
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        try:
            data = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        updated = data.replace("/home/vscode/.codex", install_root)
        if updated != data:
            path.write_text(updated, encoding="utf-8")
PY
}

write_project_config() {
  local project_root config_file
  project_root="$PROJECT_ROOT"
  config_file="$project_root/.agents/zskills-config.json"
  mkdir -p "$project_root/.agents"
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

install_project() {
  local install_root="$PROJECT_ROOT/.agents"
  mkdir -p "$install_root"
  install_skill_dirs "$install_root/skills"
  install_support_dir "$install_root/zskills-support"
  rewrite_installed_paths "$install_root"
  if [ "$WRITE_PROJECT_CONFIG" = "1" ]; then
    write_project_config
  fi
  echo "Installed Z Skills for Codex into project: $PROJECT_ROOT"
  echo "Installed project skills: $install_root/skills"
  echo "Installed project support: $install_root/zskills-support"
}

install_global() {
  mkdir -p "$CODEX_HOME"
  install_skill_dirs "$CODEX_HOME/skills"
  install_support_dir "$CODEX_HOME/zskills-support"
  rewrite_installed_paths "$CODEX_HOME"
  if [ "$WRITE_PROJECT_CONFIG" = "1" ]; then
    write_project_config
  fi
  echo "Installed Z Skills for Codex into CODEX_HOME: $CODEX_HOME"
}

if [ "$INSTALL_GLOBAL" = "1" ]; then
  install_global
else
  install_project
fi

echo "Installed Z Skills: $(find "$ROOT/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
echo "Restart Codex if you need updated skill metadata to be discovered."
