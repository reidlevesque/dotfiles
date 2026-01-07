#! /bin/zsh

if [[ "$(/usr/bin/uname 2>/dev/null || uname)" == "Linux" ]]; then
  function code {
    local VSCODE_SERVER=$(ls -td $HOME/.cursor-server/cli/servers/Stable-*[0-9] | head -1)
    # needed to be able to open files in VS Code's editor from the command line
    export VSCODE_IPC_HOOK_CLI="$( ls -td /run/user/$UID/vscode-ipc-*.sock | head -1)"

    $VSCODE_SERVER/server/bin/remote-cli/cursor $@
  }
fi
