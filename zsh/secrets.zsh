#! /bin/zsh

mkdir -p "$HOME/.secrets"
for file in "$HOME/.secrets"/*; do
  chmod 600 "$file"
done
chmod 700 "$HOME/.secrets"

[ -f "$HOME/.secrets/openai" ] && source "$HOME/.secrets/openai"
