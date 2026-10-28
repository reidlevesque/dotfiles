#!/bin/bash
# Sign with the on-disk key only. ssh-keygen -Y sign asks SSH_AUTH_SOCK for
# the key first, so a forwarded agent that never answers hangs every commit.
# Opt in per machine with gpg.ssh.program in ~/.gitconfig.local.
unset SSH_AUTH_SOCK
exec ssh-keygen "$@"
