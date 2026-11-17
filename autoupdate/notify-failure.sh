#!/bin/bash
set -euo pipefail

recipient="${DOTFILES_SLACK_USER:-$(id -un)}"
host="$(hostname -s)"
status="$(systemctl --user show dotfiles-update.service \
  --property=Result --property=ExecMainStatus --property=ExecMainExitTimestamp)"

# Keep raw logs local: installer output can contain credentials or private data.
message="Dotfiles update failed on $host.

$status

Check the logs on $host:
journalctl --user -u dotfiles-update.service -n 80 --no-pager"

slack --user "$recipient" --message "$message"
printf 'Sent dotfiles update failure notification to %s.\n' "$recipient"
