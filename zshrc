#! /bin/zsh

# . $HOME/.zsh/antigenrc
. $HOME/.zsh/ohmyzshrc

# User configuration

. $HOME/.zsh/zsh_functions
. $HOME/.zsh/zsh_aliases
. $HOME/.zsh/zsh_kubernetes
. $HOME/.zsh/zsh_environ
. $HOME/.zsh/zsh_prompt
. $HOME/.zsh/.secrets
. $HOME/dev/au/engineering/kubernetes/kuberc
. $HOME/dev/au/engineering/kubernetes/kuberc_china
. $HOME/.zshenv
. $HOME/.brewrc

eval "$(pyenv init -)"
eval "$(jenv init -)"
