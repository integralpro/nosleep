#!/bin/sh

COMMON_DEFINED=yes

KEXT_ID=com.protech.NoSleep
KEXT_PATH=/System/Library/Extensions/NoSleep.kext
PERF_PATH=/Library/PreferencePanes/NoSleep.prefPane
HELPER_PATH=/Applications/Utilities/NoSleep.app
AGENT_PATH=/Library/LaunchAgents/com.protech.NoSleep.plist

USER_SUDO_CMD=""

if [ "$SUDO_USER" != "" ]; then
	USER_SUDO_CMD="sudo -u $SUDO_USER"
else if [ "$USER" != "" ]; then
	USER_SUDO_CMD="sudo -u $USER"
fi
fi
