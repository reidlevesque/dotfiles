#!/bin/bash
#
# Run all dotfiles installers.
set -euo pipefail

cd "$(dirname "$0")"

export DOTFILES; DOTFILES=$(pwd)
export ICLOUD_CONFIG=~/Library/Mobile\ Documents/com\~apple\~CloudDocs/Config

load_homebrew_shellenv() {
  local brew_bin

  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$brew_bin" ]]; then
      eval "$("$brew_bin" shellenv)"
      return 0
    fi
  done

  return 1
}

install_homebrew_if_missing() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  if load_homebrew_shellenv; then
    return
  fi

  echo -e "\\n> Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if ! command -v brew >/dev/null 2>&1 && ! load_homebrew_shellenv; then
    echo "Homebrew was installed, but brew was not found on PATH." >&2
    exit 1
  fi
}

install_oh_my_zsh_if_missing() {
  if [[ -d "${ZSH:-$HOME/.oh-my-zsh}" ]]; then
    return
  fi

  echo -e "\\n> Installing Oh My Zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_or_update_mise() {
  local mise_bin="${MISE_INSTALL_PATH:-$HOME/.local/bin/mise}"

  mkdir -p "$(dirname "$mise_bin")"

  if [[ -x "$mise_bin" ]]; then
    echo -e "\\n> Updating mise"
    if "$mise_bin" self-update -y; then
      return
    fi

    echo "mise self-update failed; reinstalling via mise.run"
  else
    echo -e "\\n> Installing mise"
  fi

  curl -fsSL https://mise.run | MISE_INSTALL_PATH="$mise_bin" sh
}

install_oh_my_zsh_if_missing
install_or_update_mise

echo -e "\\n› Creating symlinks"
shared_symlinks='*.symlink'
platform_symlinks="*.symlink.$(uname)"

while IFS= read -r -d '' src; do
  if [[ $src == *.md.symlink ]]; then
    ln -sfv "$src" "$HOME/$(basename "${src%.*}")"
  else
    ln -sfv "$src" "$HOME/.$(basename "${src%.*}")"
  fi
done < <(find "$DOTFILES" -name "$shared_symlinks" -print0)
while IFS= read -r -d '' src; do
  ln -sfv "$src" "$HOME/.$(basename "${src%.*.*}")"
done < <(find "$DOTFILES" -name "$platform_symlinks" -print0)

if [[ -f "Brewfile.$(uname)" ]]; then
  install_homebrew_if_missing
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
