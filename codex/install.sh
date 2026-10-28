#!/usr/bin/env bash
# Install codex from npm on macOS.
# The Homebrew cask runs its freshly quarantined binary during every upgrade to
# generate shell completions, so Gatekeeper prompts on each codex release. npm
# downloads are not quarantined. Linux keeps the cask in Brewfile.Linux.
set -euo pipefail

[[ "$(uname)" == "Darwin" ]] || exit 0

if ! command -v npm >/dev/null 2>&1; then
  echo "Cannot install codex: npm is not available." >&2
  exit 1
fi

# The cask owns $(brew --prefix)/bin/codex, which blocks the npm bin link.
if command -v brew >/dev/null 2>&1 && brew list --cask codex >/dev/null 2>&1; then
  HOMEBREW_NO_AUTOREMOVE=1 brew uninstall --cask codex
fi

npm install --global @openai/codex@latest
