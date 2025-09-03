#! /bin/zsh

function fix_permissions() {
  mkdir -p "$HOME/.secrets"
  for file in "$HOME/.secrets"/*; do
    [ -f "$file" ] && chmod 600 "$file"
  done
  chmod 700 "$HOME/.secrets"
}

# fix_permissions

[ -f "$HOME/.secrets/openai" ] && source "$HOME/.secrets/openai"
