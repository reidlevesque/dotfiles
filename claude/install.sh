#!/bin/bash
# Install or update native Claude Code on macOS. Linux uses Brewfile.Linux.
set -euo pipefail

[[ "$(uname)" == "Darwin" ]] || exit 0

curl -fsSL https://claude.ai/install.sh | bash -s -- latest
