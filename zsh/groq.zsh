#! /bin/zsh

if [ -n "$GROQ_CONFIG" ]; then
  [ -f "$GROQ_CONFIG/zsh/bake-completion.zsh" ] && . "$GROQ_CONFIG/zsh/bake-completion.zsh"
  [ -f "$GROQ_CONFIG/zsh/gr-completion.zsh" ] && . "$GROQ_CONFIG/zsh/gr-completion.zsh"
  [ -f "$GROQ_CONFIG/zsh/nix.zsh" ] && . "$GROQ_CONFIG/zsh/nix.zsh"
  [ -f "$GROQ_CONFIG/zsh/fix-sft.zsh" ] && . "$GROQ_CONFIG/zsh/fix-sft.zsh"
fi
# ssh X tmux
# alias attach="sft ssh --command \"tmux -CC new -As0\""
alias attach="ssh  \"tmux -CC new -As0\""
alias redeploy="sudo -i GROQ_LOG_CONFIG=stderr-also =groq_deploy_client --production-run"

function refresh () {
  if [ -n "$TMUX" ]; then
    eval $(tmux showenv -s)
  fi
}
autoload -Uz refresh
function preexec {
  refresh
}

function builder_tasks() {
  brake-query builder-tasks "$1" \
    "$(date +"%m-%d-%Y")" "$(date -d "tomorrow" +"%m-%d-%Y")"
}

function failed_ci_diag_tasks() {
  python3 $DOTFILES/scripts/builder_tasks.py "$@"
}

function add_slurm_user() {
  user=$1

  if [ -z "$user" ]; then
    echo "Usage: add_slurm_user <username>"
    return 1
  fi

  echo y | sacctmgr add user "$user" account=compiler fairshare=100
  echo y | sacctmgr modify user "$user" set DefaultAccount=compiler
}
