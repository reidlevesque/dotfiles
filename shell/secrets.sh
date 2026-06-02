#!/bin/sh

_dotfiles_secrets_dir="$HOME/.secrets"

_dotfiles_secrets_fix_permissions() {
  mkdir -p "$_dotfiles_secrets_dir"
  chmod 700 "$_dotfiles_secrets_dir"
  find "$_dotfiles_secrets_dir" -maxdepth 1 -type f -exec chmod 600 {} + 2>/dev/null || true
}

_dotfiles_secrets_fix_permissions

while IFS= read -r _dotfiles_secret_file; do
  [ -n "$_dotfiles_secret_file" ] || continue
  # shellcheck source=/dev/null
  . "$_dotfiles_secret_file"
done <<EOF
$(find "$_dotfiles_secrets_dir" -maxdepth 1 -type f -name '*.sh' -print 2>/dev/null | sort)
EOF

unset _dotfiles_secret_file _dotfiles_secrets_dir
unset -f _dotfiles_secrets_fix_permissions 2>/dev/null || true
