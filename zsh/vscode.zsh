#! /bin/zsh

export CURSOR_REMOTE_HOST_ALIAS="${CURSOR_REMOTE_HOST_ALIAS:-devvm-rlevesque}"
export CURSOR_BRIDGE_LOCAL_SOCKET="${CURSOR_BRIDGE_LOCAL_SOCKET:-$HOME/.cursor-bridge.sock}"
export CURSOR_BRIDGE_REMOTE_SOCKET="${CURSOR_BRIDGE_REMOTE_SOCKET:-/tmp/cursor-bridge.sock}"
export CURSOR_BRIDGE_PID_FILE="${CURSOR_BRIDGE_PID_FILE:-${TMPDIR:-/tmp}/cursor-bridge.pid}"
export CURSOR_BRIDGE_LOG_FILE="${CURSOR_BRIDGE_LOG_FILE:-${TMPDIR:-/tmp}/cursor-bridge.log}"

function _cursor_remote_authority() {
  print -r -- "ssh-remote+${CURSOR_REMOTE_HOST_ALIAS}"
}

if [[ "$(/usr/bin/uname 2>/dev/null || uname)" == "Darwin" ]]; then
  function _cursor_bridge_listener() {
    emulate -L zsh
    local request authority target

    rm -f "$CURSOR_BRIDGE_LOCAL_SOCKET"
    print -r -- $$ > "$CURSOR_BRIDGE_PID_FILE"
    trap 'rm -f "$CURSOR_BRIDGE_LOCAL_SOCKET" "$CURSOR_BRIDGE_PID_FILE"' EXIT INT TERM

    while true; do
      request="$(nc -lU "$CURSOR_BRIDGE_LOCAL_SOCKET" 2>/dev/null)" || continue
      authority="${request%%$'\n'*}"
      target="${request#*$'\n'}"
      target="${target%%$'\n'*}"

      [[ -z "$authority" || -z "$target" ]] && continue

      if command -v cursor >/dev/null 2>&1; then
        command cursor --remote "$authority" "$target" >/dev/null 2>&1 &
      else
        open -a Cursor --args --remote "$authority" "$target" >/dev/null 2>&1 &
      fi
    done
  }

  function cursor-bridge-start() {
    emulate -L zsh
    local bridge_pid=""

    if [[ -f "$CURSOR_BRIDGE_PID_FILE" ]]; then
      bridge_pid="$(<"$CURSOR_BRIDGE_PID_FILE")"
    fi

    if [[ -n "$bridge_pid" ]] && kill -0 "$bridge_pid" 2>/dev/null; then
      return 0
    fi

    if ! command -v nc >/dev/null 2>&1; then
      print -u2 -- "cursor-bridge-start: nc is required to listen for remote Cursor requests."
      return 1
    fi

    rm -f "$CURSOR_BRIDGE_PID_FILE"
    (_cursor_bridge_listener) >>"$CURSOR_BRIDGE_LOG_FILE" 2>&1 &!
  }
fi

if [[ "$(/usr/bin/uname 2>/dev/null || uname)" == "Linux" ]]; then
  function _cursor_remote_cli() {
    command ls -td "$HOME"/.cursor-server/bin/linux-x64/*/bin/remote-cli/cursor 2>/dev/null | head -1
  }

  function _cursor_ipc_hook() {
    command ls -td /run/user/$UID/vscode-ipc-*.sock 2>/dev/null | head -1
  }

  function _cursor_bridge_target() {
    emulate -L zsh
    local target="${1:-$PWD}"

    print -r -- "${target:A}"
  }

  function _cursor_bridge_request() {
    emulate -L zsh
    local target="$1"

    if ! command -v nc >/dev/null 2>&1; then
      print -u2 -- "code: nc is required for the Cursor bridge fallback."
      return 1
    fi

    if [[ ! -S "$CURSOR_BRIDGE_REMOTE_SOCKET" ]]; then
      print -u2 -- "code: Cursor is not connected yet and no bridge is available at ${CURSOR_BRIDGE_REMOTE_SOCKET}."
      print -u2 -- "code: reconnect with attach so your laptop can launch Cursor for this host."
      return 1
    fi

    printf '%s\n%s\n' "$(_cursor_remote_authority)" "$target" | nc -U "$CURSOR_BRIDGE_REMOTE_SOCKET"
  }

  function code {
    emulate -L zsh
    local cursor_cli ipc_hook

    cursor_cli="$(_cursor_remote_cli)"
    ipc_hook="$(_cursor_ipc_hook)"

    if [[ -n "$cursor_cli" && -n "$ipc_hook" ]]; then
      export VSCODE_IPC_HOOK_CLI="$ipc_hook"
      "$cursor_cli" "$@"
      return $?
    fi

    if (( $# > 1 )); then
      print -u2 -- "code: remote fallback only supports zero or one path argument."
      return 1
    fi

    if (( $# == 1 )) && [[ "$1" == -* ]]; then
      print -u2 -- "code: remote fallback only supports opening a path."
      return 1
    fi

    _cursor_bridge_request "$(_cursor_bridge_target "${1:-$PWD}")"
  }
fi
