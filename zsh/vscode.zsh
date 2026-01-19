#! /bin/zsh

if [[ "$(/usr/bin/uname 2>/dev/null || uname)" == "Linux" ]]; then
  function code {
    CURSOR_CLI=$(ls -td $HOME/.cursor-server/bin/linux-x64/*/bin/remote-cli/cursor | head -1)
    # needed to be able to open files in VS Code's editor from the command line
    export VSCODE_IPC_HOOK_CLI="$( ls -td /run/user/$UID/vscode-ipc-*.sock | head -1)"

    $CURSOR_CLI $@
  }
fi
