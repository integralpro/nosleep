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
