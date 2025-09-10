#! /bin/zsh

# Docker
function remove-all-docker-containers() {
  docker ps -aq --no-trunc | xargs docker rm
}

function remove-all-docker-images() {
  docker images | awk '{ print $3 }' | xargs -I {} docker rmi {}
}

#Fly
function fly-watch() {
  `echo $1 | perl -p -e 's#.*/pipelines/(.*)/jobs/(.*)/builds/(.*)$#fly watch -t au -j $1/$2 -b $3#g'`
}

# Random
function jwt-decode() {
  jq -R 'split(".") | .[1] | @base64d | fromjson'
}

function wol-clifford() {
  local server_ip=$(dig +short andreaandreid.ddns.net)
  wakeonlan -i "${server_ip}" -p 42464 "2c:f0:5d:98:71:fc"
}

function dev() {
  if [[ -z "$1" ]]; then
    # No parameter - run in current directory
    git up &
    code .
    return 0
  fi

  local repo_path="$HOME/dev/$1"

  if [[ ! -d "$repo_path" ]]; then
    echo "Directory $repo_path does not exist"
    return 1
  fi

  # OS-specific terminal automation
  if [[ "$(uname)" == "Darwin" ]]; then
    # AppleScript to find existing tab or create new one (macOS)
    osascript -e "
      tell application \"iTerm\"
        set repoName to \"$1\"
        set repoPath to \"$repo_path\"
        set foundTab to false

        repeat with theWindow in windows
          repeat with theTab in tabs of theWindow
            if name of current session of theTab is repoName then
              select theTab
              tell current session of theTab
                write text \"cd \" & quoted form of repoPath
                write text \"git up &\"
                write text \"code .\"
              end tell
              set foundTab to true
              exit repeat
            end if
          end repeat
          if foundTab then exit repeat
        end repeat

        if not foundTab then
          tell current window
            create tab with default profile
            tell current session
              write text \"cd '$repo_path'\"
              write text \"git up &\"
              write text \"code .\"
            end tell
          end tell
        end if
      end tell
    "
  elif [[ "$(uname)" == "Linux" ]]; then
    # tmux window management (Linux)
    local window_name="$1"
    
    if tmux list-windows -F "#{window_name}" 2>/dev/null | grep -q "^${window_name}$"; then
      # Window exists, switch to it and run commands
      tmux select-window -t "${window_name}"
      tmux send-keys -t "${window_name}" "cd '$repo_path'" C-m
      tmux send-keys -t "${window_name}" "git up &" C-m
      tmux send-keys -t "${window_name}" "code ." C-m
    else
      # Create new window and run commands
      tmux new-window -n "${window_name}" -c "$repo_path"
      tmux send-keys -t "${window_name}" "git up &" C-m
      tmux send-keys -t "${window_name}" "code ." C-m
    fi
  fi
}

# Tab completion for dev function
_dev() {
  local -a repos
  repos=(${HOME}/dev/*(/:t))
  _describe 'repositories' repos
}
compdef _dev dev
