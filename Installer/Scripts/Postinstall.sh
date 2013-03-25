#!/bin/sh

if [ "$COMMON_DEFINED" = "" ]; then
	source `dirname "$0"`/Common.sh
fi

sudo kextload "$KEXT_PATH"

$USER_SUDO_CMD launchctl load $LAUNCH_DAEMON_PATH

defaults write /Library/Preferences/loginwindow AutoLaunchedApplicationDictionary -array-add '{Path="$HELPER_PATH";}'
open $HELPER_PATH

echo "Done"
