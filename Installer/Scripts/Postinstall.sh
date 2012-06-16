#!/bin/sh

if [ "$COMMON_DEFINED" = "" ]; then
	source `dirname "$0"`/Common.sh
fi

sudo kextload "$KEXT_PATH"

$USER_SUDO_CMD launchctl unload -S Aqua $AGENT_PATH
$USER_SUDO_CMD launchctl load -S Aqua $AGENT_PATH

echo "Done"
