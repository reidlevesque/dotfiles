#!/usr/bin/env bash
# Link personal CLI wrappers into ~/bin.
set -euo pipefail

src_dir="$(cd "$(dirname "$0")" && pwd -P)"
mkdir -p "$HOME/bin"

for src in "$src_dir"/*; do
  [[ -f "$src" && -x "$src" ]] || continue
  [[ "$(basename "$src")" == "install.sh" ]] && continue
  ln -sfv "$src" "$HOME/bin/$(basename "$src")"
done
