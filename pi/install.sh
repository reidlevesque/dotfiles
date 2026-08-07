#!/usr/bin/env bash
set -euo pipefail

if ! command -v npm >/dev/null 2>&1; then
  echo "Cannot install Pi: npm is not available." >&2
  exit 1
fi

exec npm install -g --ignore-scripts @earendil-works/pi-coding-agent
