#! /bin/bash

zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
plugins_dir="$zsh_custom/plugins"

mkdir -p "$plugins_dir"

if [[ ! -d "$plugins_dir/zsh-autosuggestions" ]]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"
fi
if [[ ! -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins_dir/zsh-syntax-highlighting"
fi
