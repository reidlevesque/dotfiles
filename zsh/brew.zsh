#! /bin/zsh

export HOMEBREW_NO_ENV_HINTS=true

if [[ -x /opt/homebrew/bin/brew ]]; then
  brew_path="/opt/homebrew"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  brew_path="/home/linuxbrew/.linuxbrew"
fi

# This is to slow so I copied it here
# eval "$(brew shellenv)"
export HOMEBREW_PREFIX="${brew_path}";
export HOMEBREW_CELLAR="${brew_path}/Cellar";
export HOMEBREW_CASKROOM="${brew_path}/Caskroom";
export HOMEBREW_REPOSITORY="${brew_path}";
fpath[1,0]="${brew_path}/share/zsh/site-functions";
export PATH="${brew_path}/bin:/opt/homebrew/sbin:${PATH}";
[ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}";
export INFOPATH="${brew_path}/share/info:${INFOPATH:-}";

