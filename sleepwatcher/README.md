# Sleepwatcher

Taken from https://www.kodiakskorner.com/log/258.
This will turn off bluetooth when the computer goes to sleep.

## Setup

```sh
brew install sleepwatcher blueutil

ln -s ~/.zsh/sleepwatcher/de.bernhard-baehr.sleepwatcher-20compatibility-localuser.plist ~/Library/LaunchAgents
launchctl load ~/Library/LaunchAgents/de.bernhard-baehr.sleepwatcher-20compatibility-localuser.plist
```
