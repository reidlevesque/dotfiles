# Sleepwatcher

Taken from https://www.kodiakskorner.com/log/258.
This will turn off bluetooth when the computer goes to sleep.

## Setup

```sh
brew install sleepwatcher blueutil

# arm
ln -s ~/.zsh/sleepwatcher/de.bernhard-baehr.sleepwatcher-20compatibility-localuser-arm.plist ~/Library/LaunchAgents
launchctl load ~/Library/LaunchAgents/de.bernhard-baehr.sleepwatcher-20compatibility-localuser-arm.plist

# x86
ln -s ~/.zsh/sleepwatcher/de.bernhard-baehr.sleepwatcher-20compatibility-localuser-x86.plist ~/Library/LaunchAgents
launchctl load ~/Library/LaunchAgents/de.bernhard-baehr.sleepwatcher-20compatibility-localuser-x86.plist
```

### Debugging

Uncomment lines in `.plist`

```xml
<!-- <key>StandardErrorPath</key>
<string>/Users/reid/logs/sleepwatcher-arm.err</string>
<key>StandardOutPath</key>
<string>/Users/reid/logs/sleepwatcher-arm.out</string>  -->
```
