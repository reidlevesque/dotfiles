#!/bin/bash
set -euo pipefail

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

cd $HOME/.dotfiles
caffeinate -i ./install.sh
