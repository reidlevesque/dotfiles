#! /bin/zsh

# ssh X tmux - iTerm tmux integration mode
attach () {
	if [[ "$TERM_PROGRAM" != "iTerm.app" ]]
	then
		osascript -e 'tell application "iTerm" to create window with default profile command "ssh devvm-rlevesque -t \"tmux -CC new -As0\""'
	else
		ssh devvm-rlevesque -t 'tmux -CC new -As0'
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
