#! /bin/zsh

function ns() {
    if [ $# -lt 1 ]; then
        echo "Usage: ns <package> [command arguments]"
        return 1
    fi

    package="$1"
    shift
    nix-shell -p "$package" --command "$package $*"
}
