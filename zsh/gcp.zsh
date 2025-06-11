#! /bin/zsh

alias g='gcloud'
alias glogin='gcloud auth login --brief --launch-browser --update-adc'
#alias glogin='gcloud auth application-default login'
alias gprojects='gcloud projects list | grep'

function gcurl () {
  local token=$(gcloud auth print-access-token)
  curl --header "Authorization: Bearer $token" $@
}

# export CLOUDSDK_PYTHON="$HOME/.pyenv/shims/python3"
export CLOUDSDK_PYTHON_SITEPACKAGES=1

[ -f "$HOMEBREW_CASKROOM/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc" ] && . "$HOMEBREW_CASKROOM/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
[ -f "$HOMEBREW_CASKROOM/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc" ] && . "$HOMEBREW_CASKROOM/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"

function gassets () {
  local project=$1
  local asset_type=${2:-}

  if [[ -z "${asset_type}" ]]; then
    gcloud asset search-all-resources \
      --scope=projects/${project} \
      --format json \
    | jq '.[].assetType'
  else
    gcloud asset search-all-resources \
      --scope=projects/${project} \
      --format json \
    | jq ".[] | select(.assetType == \"${asset_type}\")"
  fi
}
