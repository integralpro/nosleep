#!/bin/sh

KEXT_PATH=/System/Library/Extensions/NoSleep.kext
HELPER_PATH=/Applications/Utilities/NoSleepHelper.app

sudo kextload "$KEXT_PATH"

#defaults write loginwindow AutoLaunchedApplicationDictionary -array-add \
#'<dict><key>Hide</key><false/><key>Path</key><string>'$HELPER_PATH'</string></dict>'

open "$HELPER_PATH" --args --register-loginitem

echo "Done"
