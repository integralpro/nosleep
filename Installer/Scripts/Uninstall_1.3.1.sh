#!/bin/sh

echo "Uninstalling 1.3.1"
sudo echo

KEXT_ID=com.protech.NoSleep
KEXT_PATH=/System/Library/Extensions/NoSleep.kext
PERF_PATH=/Library/PreferencePanes/NoSleep.prefPane
HELPER_PATH=/Applications/Utilities/NoSleep.app
AGENT_PATH=/Library/LaunchAgents/com.protech.NoSleep.plist

if [ -e "$AGENT_PATH" ]; then
	echo "Removing LaunchAgent..."
	sudo launchctl load "$AGENT_PATH"
	sudo launchctl stop $KEXT_ID
	sudo launchctl unload "$AGENT_PATH"
	sudo rm -f "$AGENT_PATH"
fi

if [ -e "$HELPER_PATH" ]; then
    echo "Removing NoSleep.app..."
    #open "$HELPER_PATH" --args --unregister-loginitem
    #sleep 5
	#ps aux|grep NoSleep.app|awk '{print $2}'|xargs kill &> /dev/null
    sudo rm -rf "$HELPER_PATH"
fi

if kextstat | grep "$KEXT_ID" > /dev/null; then
    echo "Unloading kernel extension..."
    sudo kextunload -b "$KEXT_ID"
fi

if [ -e "$KEXT_PATH" ]; then
    echo "Removing kernel extension..."
    sudo rm -rf "$KEXT_PATH"
fi

if [ -e "$PERF_PATH" ]; then
    echo "Removing preferences plug-in..."
    sudo rm -rf "$PERF_PATH"
fi

sudo pkgutil --forget "com.protech.pkg.NoSleep" &> /dev/null
sudo pkgutil --forget "com.protech.pkg.NoSleepCtrl" &> /dev/null

echo "Done"