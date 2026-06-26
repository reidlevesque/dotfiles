#! /bin/zsh

if [[ ! -f "$HOME/.config/nvidia/lpu-bootstrap.sh" ]]; then
  eval "$(~/.local/bin/mise activate zsh)"
fi

mise () {
	if [ -z "${MISE_GITHUB_TOKEN}" ]
	then
		export MISE_GITHUB_TOKEN=$(command gh auth token 2>/dev/null)
	fi
	if typeset -f _mise_original > /dev/null 2>&1
	then
		_mise_original "$@"
	else
		command mise "$@"
	fi
}
