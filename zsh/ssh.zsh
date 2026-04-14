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

function _attach_remote_port() {
	emulate -L zsh
	local min_port port_range

	min_port=49152
	port_range=16384

	print -r -- $(( min_port + (((RANDOM << 15) + RANDOM + $$ + EPOCHSECONDS) % port_range) ))
}

function _attach_uses_remote_tcp_bridge() {
	emulate -L zsh
	local remote_host="$1"
	local proxy_command

	proxy_command="$(
		command ssh -G "$remote_host" 2>/dev/null |
			awk '$1 == "proxycommand" { $1 = ""; sub(/^ /, ""); print; exit }'
	)"

	[[ "$proxy_command" == *"tsh proxy ssh"* ]]
}

function _attach_remote_command() {
	emulate -L zsh
	local remote_socket="$1"
	local remote_port="$2"
	local remote_host="$3"
	local -a remote_commands

	remote_commands=(
		"tmux set-environment -g CURSOR_REMOTE_HOST_ALIAS ${(q)remote_host}"
		"tmux set-environment -g SSH_AUTH_SOCK \"\$SSH_AUTH_SOCK\""
	)

	if [[ -n "$remote_port" ]]
	then
		remote_commands+=(
			"tmux set-environment -g CURSOR_BRIDGE_REMOTE_PORT ${(q)remote_port}"
			"tmux set-environment -gu CURSOR_BRIDGE_REMOTE_SOCKET"
		)
	else
		remote_commands+=(
			"tmux set-environment -g CURSOR_BRIDGE_REMOTE_SOCKET ${(q)remote_socket}"
			"tmux set-environment -gu CURSOR_BRIDGE_REMOTE_PORT"
		)
	fi

	remote_commands+=("tmux -CC new -As0")
	print -r -- "${(j:; :)remote_commands}"
}

# ssh X tmux - iTerm tmux integration mode
attach () {
	local remote_host remote_socket remote_port remote_command ssh_command
	local -a ssh_args

	remote_host="${1:-${CURSOR_REMOTE_HOST_ALIAS:-devvm-rlevesque}}"
	export CURSOR_REMOTE_HOST_ALIAS="$remote_host"

	if _attach_uses_remote_tcp_bridge "$remote_host"
	then
		remote_port="$(_attach_remote_port)"
		remote_command="$(_attach_remote_command "" "$remote_port" "$remote_host")"
	else
		remote_socket="$(_attach_remote_socket)"
		remote_command="$(_attach_remote_command "$remote_socket" "" "$remote_host")"
	fi

	if typeset -f cursor-bridge-start >/dev/null 2>&1; then
		cursor-bridge-start >/dev/null 2>&1 || true
	fi

	if [[ -n "$remote_port" ]]
	then
		# Teleport accepts remote TCP listeners but rejects remote UNIX socket listeners.
		ssh_args=(
			-o ControlMaster=no
			-o ControlPath=none
			-o ControlPersist=no
			-o ExitOnForwardFailure=yes
			-o StreamLocalBindUnlink=yes
			# Avoid ControlPersist collisions by giving attach its own SSH session and bridge socket.
			-R "${remote_port}:${CURSOR_BRIDGE_LOCAL_SOCKET}"
			"$remote_host"
			-t
			"$remote_command"
		)
	else
		ssh_args=(
			-o ControlMaster=no
			-o ControlPath=none
			-o ControlPersist=no
			-o ExitOnForwardFailure=yes
			-o StreamLocalBindUnlink=yes
			# Avoid ControlPersist collisions by giving attach its own SSH session and bridge socket.
			-R "${remote_socket}:${CURSOR_BRIDGE_LOCAL_SOCKET}"
			"$remote_host"
			-t
			"$remote_command"
		)
	fi

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
