#!/bin/bash
set -euo pipefail

if ! command -v cargo >/dev/null 2>&1; then
  echo "Skipping turbo-review install; cargo is not available"
  exit 0
fi

if ! command -v cc >/dev/null 2>&1; then
  echo "Skipping turbo-review install; cc is not available"
  exit 0
fi

cargo install --path turbo-review/scripts/turbo-review --locked
