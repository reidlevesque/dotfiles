#! /bin/zsh

#. $HOME/.zsh/antigenrc
. $HOME/.zsh/ohmyzshrc

# User configuration

. $HOME/.zsh/zsh_functions
. $HOME/.zsh/zsh_aliases
. $HOME/.zsh/zsh_kubernetes
. $HOME/.zsh/zsh_cloud
. $HOME/.zsh/zsh_environ
. $HOME/.zsh/zsh_prompt
[ -f $HOME/dev/au/engineering/kubernetes/kuberc ] && . $HOME/dev/au/engineering/kubernetes/kuberc
[ -f $HOME/dev/au/engineering/kubernetes/kuberc_china ] && . $HOME/dev/au/engineering/kubernetes/kuberc_china
[ -f $HOME/.zshenv ] && . $HOME/.zshenv
[ -f $HOME/.brewrc ] && . $HOME/.brewrc
[ -f /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Keep history per shell (i.e. don't share)
#setopt noincappendhistory
#setopt nosharehistory

# eval "$(jenv init -)" # Slow
. $HOME/.zsh/zsh_python # keep this last
