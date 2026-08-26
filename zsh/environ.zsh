#! /bin/zsh

export TZ="America/New_York"

if [[ $OSTYPE == linux* ]]; then
  export BUILDKITE_NO_KEYRING=1
fi
