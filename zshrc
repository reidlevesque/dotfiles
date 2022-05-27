#! /bin/zsh

. $HOME/.zsh/ohmyzshrc

# Language Specific Files
. $HOME/.zsh/zsh_gcp
. $HOME/.zsh/zsh_kubernetes
. $HOME/.zsh/zsh_terraform
. $HOME/.zsh/zsh_brew
. $HOME/.zsh/zsh_git

# General Purpose Files
. $HOME/.zsh/zsh_functions
. $HOME/.zsh/zsh_aliases
. $HOME/.zsh/zsh_environ
. $HOME/.zsh/zsh_prompt

# Keep history per shell (i.e. don't share)
#setopt noincappendhistory
#setopt nosharehistory

. $HOME/.zsh/zsh_python # keep this last
