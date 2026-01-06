#! /bin/bash

mkdir -p ~/.config
rm -rf ~/.config/atuin
ln -sfv $DOTFILES/atuin ~/.config/
