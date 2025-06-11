#! /bin/zsh

function aider() {
  if [[ -f "$HOME/.secrets/aider" ]]; then
    source "$HOME/.secrets/aider"
  fi
  command aider \
    --model groq/deepseek-r1-distill-llama-70b \
    --openai-api-base "https://api.groq.com/v1" \
    "$@"
}
