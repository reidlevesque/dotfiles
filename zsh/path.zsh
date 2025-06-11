#! /bin/zsh

export PATH="$PATH:$HOME/.krew/bin"
export PATH="$PATH:$HOME/.jenv/bin"
export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"
export PATH="$PATH:$HOME/go/bin"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$HOME/bin:$PATH"

# kubernetes
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# ruby
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="/opt/homebrew/lib/ruby/gems/3.3.0/bin:$PATH"
