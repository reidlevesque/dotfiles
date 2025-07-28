#!/bin/bash
#
# Run all dotfiles installers.
set -euo pipefail

cd "$(dirname "$0")"

export DOTFILES; DOTFILES=$(pwd)
export ICLOUD_CONFIG=~/Library/Mobile\ Documents/com\~apple\~CloudDocs/Config

echo -e "\\n› Creating symlinks"
while IFS= read -r -d '' src; do
  if [[ $src == *.md.symlink ]]; then
    ln -sfv "$src" "$HOME/$(basename "${src%.*}")"
  else
    ln -sfv "$src" "$HOME/.$(basename "${src%.*}")"
  fi

  ln -sfv "$src" "$HOME/.$(basename "${src%.*}")"
done < <(find "$DOTFILES" -name '*.symlink' -print0)

if [[ -f "Brewfile.$(uname)" ]]; then
  echo -e "\\n> Installing Bundle"
  brew bundle install --file="Brewfile.$(uname)"
fi

install_scripts=()
while IFS= read -r -d $'\0' script; do
  install_scripts+=("$script")
done < <(find "$DOTFILES" -name 'install.sh' -mindepth 2 -print0)

for script in "${install_scripts[@]}"; do
  echo -e "\\n> Running installer $script"
  bash -eu -o pipefail "$script"
done

echo -e "\\n> Done!"
