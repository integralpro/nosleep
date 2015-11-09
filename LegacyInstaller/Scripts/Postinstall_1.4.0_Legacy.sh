#!/bin/sh

if [ "$COMMON_DEFINED" = "" ]; then
	source `dirname "$0"`/Common.sh
fi

if ! kextstat | grep "$KEXT_ID" > /dev/null; then
    sudo kextload "$LEGACY_KEXT_PATH"
fi

open $HELPER_PATH

echo "Done"
