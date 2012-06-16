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
