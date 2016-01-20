#!/bin/sh

COMMON_DEFINED=yes

KEXT_ID=com.protech.NoSleep
KEXT_PATH=/Library/Extensions/NoSleep.kext
PERF_PATH=/Library/PreferencePanes/NoSleep.prefPane
HELPER_PATH=/Applications/Utilities/NoSleep.app
LAUNCH_DAEMON_PATH=/Library/LaunchAgents/$KEXT_ID.plist

USER_SUDO_CMD=""

if [ "$SUDO_USER" != "" ]; then
	USER_SUDO_CMD="sudo -u $SUDO_USER"
else if [ "$USER" != "" ]; then
	USER_SUDO_CMD="sudo -u $USER"
fi
fi
