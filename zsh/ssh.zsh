#! /bin/zsh

# ssh X tmux - iTerm tmux integration mode
attach () {
	local ssh_command

	if typeset -f cursor-bridge-start >/dev/null 2>&1; then
		cursor-bridge-start >/dev/null 2>&1 || true
	fi

	ssh_command="ssh -o StreamLocalBindUnlink=yes -R ${CURSOR_BRIDGE_REMOTE_SOCKET}:${CURSOR_BRIDGE_LOCAL_SOCKET} devvm-rlevesque -t 'tmux -CC new -As0'"

	if [[ "$TERM_PROGRAM" != "iTerm.app" ]]
	then
		/usr/bin/osascript -e "tell application \"iTerm\" to create window with default profile command \"$ssh_command\""
	else
		ssh -o StreamLocalBindUnlink=yes -R "${CURSOR_BRIDGE_REMOTE_SOCKET}:${CURSOR_BRIDGE_LOCAL_SOCKET}" devvm-rlevesque -t 'tmux -CC new -As0'
	fi
}
# Old sft version:
# alias attach="sft ssh --command \"tmux -CC new -As0\""

function refresh () {
  if [ -n "$TMUX" ]; then
    eval $(tmux showenv -s)
  fi
}
autoload -Uz refresh
function preexec {
  refresh
}
