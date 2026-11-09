#!/usr/bin/env bash
set -euo pipefail

scene="${1:?Usage: run_godot_test.sh <scene-path> <expected-output-marker>}"
expected_marker="${2:?Expected test completion marker is required}"
log_file="$(mktemp)"
trap 'rm -f "$log_file"' EXIT

set +e
godot -v --headless --path . "$scene" 2>&1 | tee "$log_file"
godot_status=${PIPESTATUS[0]}
set -e

if [[ "$godot_status" -ne 0 ]]; then
  echo "Godot test process failed with exit code $godot_status."
  exit "$godot_status"
fi

if grep -E "SCRIPT ERROR:|Failed to load script|Parse Error:|Compile Error:|FAILED|SOME TESTS FAILED" "$log_file"; then
  echo "Godot reported a script error or failed assertion."
  exit 1
fi

if ! grep -Fq "$expected_marker" "$log_file"; then
  echo "Expected test completion marker was not found: $expected_marker"
  exit 1
fi
