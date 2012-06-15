#!/bin/sh

KEXT_PATH=/System/Library/Extensions/NoSleep.kext
HELPER_PATH=/Applications/Utilities/NoSleep.app
AGENT_PATH=/Library/LaunchAgents/com.protech.NoSleep.plist

sudo kextload "$KEXT_PATH"

#defaults write loginwindow AutoLaunchedApplicationDictionary -array-add \
#'<dict><key>Hide</key><false/><key>Path</key><string>'$HELPER_PATH'</string></dict>'

#open "$HELPER_PATH" --args --register-loginitem
sudo launchctl load "$AGENT_PATH"
sudo launchctl start com.protech.NoSleep

echo "Done"
