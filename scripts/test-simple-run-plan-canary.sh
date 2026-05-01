#!/usr/bin/env bash
set -euo pipefail

manifest="canary-output/manifest.txt"

if [[ ! -f "$manifest" ]]; then
  echo "Missing $manifest" >&2
  exit 1
fi

mapfile -t entries < "$manifest"

expected=(
  "phase-1-alpha.txt"
  "phase-2-beta.txt"
  "phase-3-gamma.txt"
)

if (( ${#entries[@]} < 1 || ${#entries[@]} > ${#expected[@]} )); then
  echo "Manifest must contain 1-${#expected[@]} entries" >&2
  exit 1
fi

for i in "${!entries[@]}"; do
  if [[ "${entries[$i]}" != "${expected[$i]}" ]]; then
    echo "Unexpected manifest entry at line $((i + 1)): ${entries[$i]}" >&2
    exit 1
  fi
done

check_file() {
  local file="$1"
  local expected_content="$2"
  local path="canary-output/$file"

  if [[ ! -f "$path" ]]; then
    echo "Missing $path" >&2
    exit 1
  fi

  if [[ "$(cat "$path")"$'\n' != "$expected_content" ]]; then
    echo "Unexpected contents in $path" >&2
    exit 1
  fi
}

for entry in "${entries[@]}"; do
  case "$entry" in
    phase-1-alpha.txt)
      check_file "$entry" $'phase=1\nname=alpha\nstatus=complete\n'
      ;;
    phase-2-beta.txt)
      check_file "$entry" $'phase=2\nname=beta\nstatus=complete\n'
      ;;
    phase-3-gamma.txt)
      check_file "$entry" $'phase=3\nname=gamma\nstatus=complete\n'
      ;;
    *)
      echo "Unknown manifest entry: $entry" >&2
      exit 1
      ;;
  esac
done
