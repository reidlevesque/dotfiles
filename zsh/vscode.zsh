#! /bin/zsh

export CURSOR_REMOTE_HOST_ALIAS="${CURSOR_REMOTE_HOST_ALIAS:-devvm-rlevesque}"
export CURSOR_BRIDGE_LOCAL_SOCKET="${CURSOR_BRIDGE_LOCAL_SOCKET:-$HOME/.cursor-bridge.sock}"
export CURSOR_BRIDGE_REMOTE_SOCKET="${CURSOR_BRIDGE_REMOTE_SOCKET:-/tmp/cursor-bridge.sock}"
export CURSOR_BRIDGE_PID_FILE="${CURSOR_BRIDGE_PID_FILE:-${TMPDIR:-/tmp}/cursor-bridge.pid}"
export CURSOR_BRIDGE_LOG_FILE="${CURSOR_BRIDGE_LOG_FILE:-${TMPDIR:-/tmp}/cursor-bridge.log}"
export CURSOR_BRIDGE_LISTENER="${CURSOR_BRIDGE_LISTENER:-$DOTFILES/scripts/cursor-bridge-listener}"

function _cursor_remote_authority() {
  print -r -- "ssh-remote+${CURSOR_REMOTE_HOST_ALIAS}"
}

if [[ "$(/usr/bin/uname 2>/dev/null || uname)" == "Darwin" ]]; then
  function cursor-bridge-start() {
    emulate -L zsh
    local bridge_pid=""

    if [[ -f "$CURSOR_BRIDGE_PID_FILE" ]]; then
      bridge_pid="$(<"$CURSOR_BRIDGE_PID_FILE")"
    fi

    if [[ -n "$bridge_pid" ]] && kill -0 "$bridge_pid" 2>/dev/null; then
      return 0
    fi

    rm -f "$CURSOR_BRIDGE_LOCAL_SOCKET" "$CURSOR_BRIDGE_PID_FILE"

    if [[ ! -x "$CURSOR_BRIDGE_LISTENER" ]]; then
      print -u2 -- "cursor-bridge-start: listener script is missing or not executable at ${CURSOR_BRIDGE_LISTENER}."
      return 1
    fi

    "$CURSOR_BRIDGE_LISTENER" "$CURSOR_BRIDGE_LOCAL_SOCKET" >>"$CURSOR_BRIDGE_LOG_FILE" 2>&1 </dev/null &
    bridge_pid=$!
    disown "$bridge_pid" 2>/dev/null || true
    print -r -- "$bridge_pid" > "$CURSOR_BRIDGE_PID_FILE"
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

  function _cursor_bridge_kind() {
    emulate -L zsh
    local target="$1"

    if [[ -d "$target" ]]; then
      print -r -- "folder"
      return 0
    fi

    if [[ -f "$target" ]]; then
      print -r -- "file"
      return 0
    fi

    print -r -- "path"
  }

  function _cursor_bridge_request() {
    emulate -L zsh
    local target="$1"
    local kind="$2"
    local remote_port="${CURSOR_BRIDGE_REMOTE_PORT:-}"

    if ! command -v nc >/dev/null 2>&1; then
      print -u2 -- "code: nc is required for the Cursor bridge fallback."
      return 1
    fi

    if [[ -n "$remote_port" ]]; then
      printf '%s\n%s\n%s\n' "$(_cursor_remote_authority)" "$kind" "$target" | nc -N 127.0.0.1 "$remote_port"
      return $?
    fi

    if [[ ! -S "$CURSOR_BRIDGE_REMOTE_SOCKET" ]]; then
      print -u2 -- "code: Cursor is not connected yet and no bridge is available at ${CURSOR_BRIDGE_REMOTE_SOCKET}."
      print -u2 -- "code: reconnect with attach so your laptop can launch Cursor for this host."
      return 1
    fi

    printf '%s\n%s\n%s\n' "$(_cursor_remote_authority)" "$kind" "$target" | nc -N -U "$CURSOR_BRIDGE_REMOTE_SOCKET"
  }

  function code {
    emulate -L zsh
    local cursor_cli ipc_hook cli_log exit_status

    cursor_cli="$(_cursor_remote_cli)"
    ipc_hook="$(_cursor_ipc_hook)"

    if [[ -n "$cursor_cli" && -n "$ipc_hook" ]]; then
      cli_log="$(mktemp "${TMPDIR:-/tmp}/cursor-code.XXXXXX")" || return 1
      export VSCODE_IPC_HOOK_CLI="$ipc_hook"

      if "$cursor_cli" "$@" >"$cli_log" 2>&1; then
        rm -f "$cli_log"
        return 0
      fi

      exit_status=$?

      if ! grep -qE 'Unable to connect to VS Code server|ECONNREFUSED' "$cli_log"; then
        cat "$cli_log" >&2
        rm -f "$cli_log"
        return $exit_status
      fi

      rm -f "$cli_log"
    fi

    if (( $# > 1 )); then
      print -u2 -- "code: remote fallback only supports zero or one path argument."
      return 1
    fi

    if (( $# == 1 )) && [[ "$1" == -* ]]; then
      print -u2 -- "code: remote fallback only supports opening a path."
      return 1
    fi

    local target kind
    target="$(_cursor_bridge_target "${1:-$PWD}")"
    kind="$(_cursor_bridge_kind "$target")"
    _cursor_bridge_request "$target" "$kind"
  }
fi
