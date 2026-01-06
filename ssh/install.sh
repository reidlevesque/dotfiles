#!/bin/bash

test -d ~/.ssh || {
	mkdir ~/.ssh
}

if [[ "$(uname)" == "Darwin" ]]; then
	ln -sfv "$DOTFILES"/ssh/config ~/.ssh/config
	mkdir -p ~/.ssh/sockets
fi

# test -f "${ICLOUD_CONFIG}/ssh_config" || {
# 	touch ~/.ssh/config.private
# }

# test -L ~/.ssh/config.private || {
# 	ln -sfv "${ICLOUD_CONFIG}/ssh_config" ~/.ssh/config.private
# }
