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

  # AppleScript to find existing tab or create new one
  osascript -e "
    tell application \"iTerm\"
      set repoName to \"$1\"
      set repoPath to \"$repo_path\"
      set foundTab to false

      repeat with theWindow in windows
        repeat with theTab in tabs of theWindow
          if name of current session of theTab contains repoName then
            select theTab
            tell current session of theTab
              set pwdCmd to \"pwd\"
              set checkCmd to pwdCmd & \" | grep -q \" & quoted form of repoPath & \" && { git up &; code .; }\"
              write text checkCmd
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
}

# Tab completion for dev function
_dev() {
  local -a repos
  repos=(${HOME}/dev/*(/:t))
  _describe 'repositories' repos
}
compdef _dev dev
