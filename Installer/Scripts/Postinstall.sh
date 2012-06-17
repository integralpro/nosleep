#!/bin/sh

if [ "$COMMON_DEFINED" = "" ]; then
	source `dirname "$0"`/Common.sh
fi

sudo kextload "$KEXT_PATH"

defaults write /Library/Preferences/loginwindow AutoLaunchedApplicationDictionary -array-add '{Path="$HELPER_PATH";}'
open $HELPER_PATH

echo "Done"
