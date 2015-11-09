#!/bin/sh

if [ "$COMMON_DEFINED" = "" ]; then
	source `dirname "$0"`/Common.sh
fi

sudo kextload "$KEXT_PATH"

defaults write /Library/Preferences/loginwindow AutoLaunchedApplicationDictionary -array-add '{Path="$HELPER_PATH";}'

if kextstat | grep "$KEXT_ID" > /dev/null; then
    open $HELPER_PATH
fi

echo "Done"
