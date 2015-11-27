#!/bin/sh

COMMON_DEFINED=yes

KEXT_ID=com.protech.NoSleep
LEGACY_KEXT_PATH=/System/Library/Extensions/NoSleep.kext
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
#!/bin/sh

echo "Uninstalling 1.3.x"
sudo true

KEXT_ID=com.protech.NoSleep
KEXT_PATH=/System/Library/Extensions/NoSleep.kext
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

if [ -e "$HELPER_PATH" ]; then
    echo "Removing NoSleep.app..."
    ps aux|grep NoSleep.app|awk '{print $2}'|xargs kill &> /dev/null
    sudo rm -rf "$HELPER_PATH"
fi

if [ -e "$LAUNCH_DAEMON_PATH" ]; then
    echo "Removing launch daemon plist..."
    $USER_SUDO_CMD launchctl unload $LAUNCH_DAEMON_PATH &> /dev/null
    sudo rm -rf "$LAUNCH_DAEMON_PATH"
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

echo "Done"
#!/bin/sh

echo "Uninstalling 1.4.0"
sudo true

if [ "$COMMON_DEFINED" = "" ]; then
	source `dirname "$0"`/Common.sh
fi

if [ -e "$HELPER_PATH" ]; then
    echo "Removing NoSleep.app..."
    ps aux|grep NoSleep.app|awk '{print $2}'|xargs kill &> /dev/null
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

echo "Done"
#!/bin/sh

echo "Uninstalling 1.4.0 Legacy Part"
sudo true

if [ "$COMMON_DEFINED" = "" ]; then
	source `dirname "$0"`/Common.sh
fi

if kextstat | grep "$KEXT_ID" > /dev/null; then
    echo "Unloading kernel extension..."
    sudo kextunload -b "$KEXT_ID"
fi

if [ -e "$LEGACY_KEXT_PATH" ]; then
    echo "Removing legacy kernel extension..."
    sudo rm -rf "$LEGACY_KEXT_PATH"
fi

sudo pkgutil --forget "com.protech.pkg.NoSleepLegacy" &> /dev/null

echo "Done"

#!/bin/sh

echo "Uninstalling NoSleepCtrl"
sudo true

CLI_PATH=/usr/local/bin/NoSleepCtrl

if [ -e "$CLI_PATH" ]; then
    echo "Removing NoSleepCtrl..."
    sudo rm -rf "$CLI_PATH"
fi

sudo pkgutil --forget "com.protech.pkg.NoSleepCtrl" &> /dev/null

echo "Done"
