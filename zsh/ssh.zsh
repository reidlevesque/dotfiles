#! /bin/zsh

# ssh X tmux - iTerm tmux integration mode
attach () {
	local remote_host ssh_command
	local -a ssh_args

	remote_host="${1:-devvm-rlevesque}"
	ssh_args=(
		"$remote_host"
		-t
		'tmux set-environment -g SSH_AUTH_SOCK "$SSH_AUTH_SOCK"; tmux -CC new -As0'
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
