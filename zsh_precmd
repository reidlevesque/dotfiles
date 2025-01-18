#! /bin/zsh

precmd() {
    iTermSetPromptHeader
    iTermSetTitle
    if whence fix-sft &> /dev/null; then
        fix-sft
    fi
}
