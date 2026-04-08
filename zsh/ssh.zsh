#! /bin/zsh

function _attach_remote_socket() {
	emulate -L zsh
	local remote_socket suffix timestamp

	remote_socket="${CURSOR_BRIDGE_REMOTE_SOCKET:-/tmp/cursor-bridge.sock}"
	timestamp="$(/bin/date +%s 2>/dev/null || date +%s)"
	suffix="-${timestamp}-$$-${RANDOM}"

	if [[ "$remote_socket" == *.sock ]]
	then
		print -r -- "${remote_socket%.sock}${suffix}.sock"
		return 0
	fi

	print -r -- "${remote_socket}${suffix}"
}

function _attach_remote_command() {
	emulate -L zsh
	local remote_socket="$1"

	print -r -- "tmux set-environment -g CURSOR_BRIDGE_REMOTE_SOCKET ${(q)remote_socket}; tmux -CC new -As0"
}

# ssh X tmux - iTerm tmux integration mode
attach () {
	local remote_host remote_socket remote_command ssh_command
	local -a ssh_args

	remote_host="${CURSOR_REMOTE_HOST_ALIAS:-devvm-rlevesque}"
	remote_socket="$(_attach_remote_socket)"
	remote_command="$(_attach_remote_command "$remote_socket")"

	if typeset -f cursor-bridge-start >/dev/null 2>&1; then
		cursor-bridge-start >/dev/null 2>&1 || true
	fi

	# Avoid ControlPersist collisions by giving attach its own SSH session and bridge socket.
	ssh_args=(
		-o ControlMaster=no
		-o ControlPath=none
		-o ControlPersist=no
		-o ExitOnForwardFailure=yes
		-o StreamLocalBindUnlink=yes
		-R "${remote_socket}:${CURSOR_BRIDGE_LOCAL_SOCKET}"
		"$remote_host"
		-t
		"$remote_command"
	)

	if [[ "$TERM_PROGRAM" != "iTerm.app" ]]
	then
		ssh_command="$(printf '%q ' ssh "${ssh_args[@]}")"
		ssh_command="${ssh_command% }"
		/usr/bin/osascript -e "tell application \"iTerm\" to create window with default profile command \"$ssh_command\""
	else
		ssh "${ssh_args[@]}"
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
