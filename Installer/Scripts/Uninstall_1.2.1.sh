#!/bin/sh

echo "Uninstalling 1.2.1 and previous"
sudo true

KEXT_ID=com.protech.nosleep
KEXT_PATH=/System/Library/Extensions/nosleep.kext
PERF_PATH=/Library/PreferencePanes/nosleep-preferences.prefPane
OLD_PERF_PATH=/System/Library/PreferencePanes/nosleep-preferences.prefPane
AGENT_PATH=/Library/LaunchAgents/com.protech.nosleep.launch.plist
HELPER_PATH=/Library/Application\ Support/nosleep/

#if [ -e "$AGENT_PATH" ]; then
#    echo "Unloading NoSleepHelper..."
#    sudo launchctl unload "$AGENT_PATH"
#    sudo rm -rf "$AGENT_PATH"
#fi

killall NoSleepHelper &> /dev/null

if [ -e "$HELPER_PATH" ]; then
    echo "Removing NoSleepHelper..."
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

if [ -e "$OLD_PERF_PATH" ]; then
    echo "Removing old preferences plug-in..."
    sudo rm -rf "$OLD_PERF_PATH"
fi

if [ -e "$PERF_PATH" ]; then
    echo "Removing preferences plug-in..."
    sudo rm -rf "$PERF_PATH"
fi

sudo pkgutil --forget "com.protech.nosleep.kext.pkg" &> /dev/null
sudo pkgutil --forget "com.protech.nosleep.launch.pkg" &> /dev/null
sudo pkgutil --forget "com.protech.nosleep.nosleep-preferences.pkg" &> /dev/null
sudo pkgutil --forget "com.protech.nosleep.NoSleepHelper.pkg" &> /dev/null
sudo pkgutil --forget "com.protech.NoSleep.pkg" &> /dev/null
sudo pkgutil --forget "com.protech.nosleep.postflight.pkg" &> /dev/null
sudo pkgutil --forget "com.protech.nosleep.preflight.pkg" &> /dev/null

echo "Done"