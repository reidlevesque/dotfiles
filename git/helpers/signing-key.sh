#!/bin/bash
set -euo pipefail

readonly signing_key_file="${HOME}/.ssh/id_ed25519.pub"
readonly fallback_signing_key="key::ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKJ12Isd0ZtwYd0pwQRA5ISGBg7J1rsbgCpC7FCtNe/5 git-signing-key"

if [[ -r "${signing_key_file}" ]]; then
  signing_key="$(head -n 1 "${signing_key_file}")"
  if [[ -n "${signing_key}" ]]; then
    if [[ "${signing_key}" == key::* ]]; then
      printf '%s\n' "${signing_key}"
    else
      printf 'key::%s\n' "${signing_key}"
    fi
    exit 0
  fi
fi

printf '%s\n' "${fallback_signing_key}"
