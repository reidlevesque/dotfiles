#! /bin/zsh

if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

function ns() {
    if [ $# -lt 1 ]; then
        echo "Usage: ns <package> [command arguments]"
        return 1
    fi

    package="$1"
    shift
    nix-shell -p "$package" --command "$package $*"
}
