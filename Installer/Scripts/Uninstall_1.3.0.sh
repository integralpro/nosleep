#!/bin/sh

echo "Uninstalling 1.3.0"
sudo true

KEXT_ID=com.protech.NoSleep
KEXT_PATH=/System/Library/Extensions/NoSleep.kext
PERF_PATH=/Library/PreferencePanes/NoSleep.prefPane
HELPER_PATH=/Applications/Utilities/NoSleepHelper.app

ps aux|grep NoSleepHelper.app|awk '{print $2}'|xargs kill -9 &> /dev/null

if [ -e "$HELPER_PATH" ]; then
    echo "Removing NoSleepHelper..."
    open "$HELPER_PATH" --args --unregister-loginitem
    sleep 5
	ps aux|grep NoSleepHelper.app|awk '{print $2}'|xargs kill -9 &> /dev/null
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