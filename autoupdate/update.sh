#!/bin/bash
#
# Pull dotfiles and run install.sh at most once a day.
#
# launchd runs this hourly and at login. A calendar job would skip days on
# which the laptop was powered off at the scheduled time.
set -euo pipefail

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-update"
stamp="$state_dir/last-success"
min_age=$((20 * 60 * 60))

now="$(date +%s)"
last=0
if [[ -f "$stamp" ]]; then
  last="$(cat "$stamp")"
fi
if [[ ! "$last" =~ ^[0-9]+$ ]]; then
  last=0
fi

if ((now - last < min_age)); then
  exit 0
fi

mkdir -p "$state_dir"
exec >"$state_dir/last-run.log" 2>&1
echo "> Started $(date)"

cd "$dotfiles_dir"
GIT_TERMINAL_PROMPT=0 git pull --no-rebase --ff-only
DOTFILES_AUTOUPDATE=1 ./install.sh

echo "$now" >"$stamp"
echo "> Finished $(date)"
