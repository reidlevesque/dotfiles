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
  local zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
  local omz_entrypoint="$zsh_dir/oh-my-zsh.sh"

  if [[ -f "$omz_entrypoint" ]]; then
    return
  fi

  if [[ -e "$zsh_dir" && ! -d "$zsh_dir" ]]; then
    echo "Cannot install Oh My Zsh: $zsh_dir exists and is not a directory." >&2
    exit 1
  fi

  if ! command -v git >/dev/null 2>&1; then
    echo "Cannot install Oh My Zsh: git is not available." >&2
    exit 1
  fi

  echo -e "\\n> Installing Oh My Zsh"

  if [[ -d "$zsh_dir" ]]; then
    local tmp_dir tmp_omz_dir
    tmp_dir="$(mktemp -d)"
    tmp_omz_dir="$tmp_dir/oh-my-zsh"

    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$tmp_omz_dir"
    cp -R "$tmp_omz_dir"/. "$zsh_dir"/
    rm -rf "$tmp_dir"
  else
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$zsh_dir"
  fi

  if [[ ! -f "$omz_entrypoint" ]]; then
    echo "Oh My Zsh install did not create $omz_entrypoint." >&2
    exit 1
  fi
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

install_apt_dependencies() {
  local aptfile
  local package
  local packages_to_install=()

  aptfile="Aptfile.$(uname)"

  if [[ ! -f "$aptfile" ]]; then
    return
  fi

  if ! command -v apt-get >/dev/null 2>&1; then
    echo "Cannot install $aptfile: apt-get is not available." >&2
    exit 1
  fi

  while IFS= read -r package || [[ -n "$package" ]]; do
    package="${package%%#*}"
    package="${package#"${package%%[![:space:]]*}"}"
    package="${package%"${package##*[![:space:]]}"}"

    if [[ -z "$package" ]]; then
      continue
    fi

    if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "ok installed"; then
      packages_to_install+=("$package")
    fi
  done < "$aptfile"

  if (( ${#packages_to_install[@]} == 0 )); then
    return
  fi

  echo -e "\\n> Installing apt dependencies"
  sudo apt-get install -y "${packages_to_install[@]}"
}

install_oh_my_zsh_if_missing
install_or_update_mise
install_apt_dependencies

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
  brew bundle install --upgrade --file="Brewfile.$(uname)"
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
