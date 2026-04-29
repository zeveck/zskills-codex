#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"

usage() {
  cat <<'EOF'
Usage: scripts/install.sh [--codex-home <path>]

Installs this Codex Z Skills distribution into CODEX_HOME.
It does not write skills or support assets into the current project repo.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --codex-home)
      CODEX_HOME="$2"
      shift 2
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

echo "Installed Z Skills for Codex into $CODEX_HOME"
echo "Installed Z Skills: $(find "$ROOT/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
echo "Restart Codex if you need updated skill metadata to be discovered."
