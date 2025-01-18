#! /bin/zsh

PROFILE=false
if [[ "${PROFILE}" = true ]]; then
  zmodload zsh/zprof
fi

# Path-Setters
# We need to load these before ohmyzshrc so that the PATH is set correctly for the plugins
. $HOME/.zsh/zsh_vscode
. $HOME/.zsh/zsh_brew # keep this first
. $HOME/.zsh/zsh_path

# Oh My Zsh
. $HOME/.zsh/ohmyzshrc

# Language Specific Files
. $HOME/.zsh/zsh_gcp
. $HOME/.zsh/zsh_kubernetes
. $HOME/.zsh/zsh_terraform
. $HOME/.zsh/zsh_git
. $HOME/.zsh/zsh_pnpm
. $HOME/.zsh/zsh_iterm
. $HOME/.zsh/zsh_haskell
. $HOME/.zsh/zsh_groq
. $HOME/.zsh/zsh_ruby
. $HOME/.zsh/zsh_aider
. $HOME/.zsh/zsh_task

# These are slow :(
. $HOME/.zsh/zsh_hermit

# General Purpose Files
. $HOME/.zsh/zsh_functions
. $HOME/.zsh/zsh_aliases
. $HOME/.zsh/zsh_prompt
. $HOME/.zsh/zsh_environ

# Keep history per shell (i.e. don't share)
#setopt noincappendhistory
#setopt nosharehistory

# Keep this last
. $HOME/.zsh/zsh_precmd
. $HOME/.zsh/zsh_completion

# This makes sure we don't exit with a non-zero status and pollute the shell
true
