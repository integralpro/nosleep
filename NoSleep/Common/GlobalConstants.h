//
//  GlobalConstants.h
//  nosleep
//
//  Created by Pavel Prokofiev on 4/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#define _STR(x) #x
#define STR(x) _STR(x)

// Extension part
#define NoSleepExtension com_protech_nosleepextension
#define NoSleepClientClass com_protech_nosleepclientclass
#define kNoSleepCommandDisabled iokit_vendor_specific_msg(0)
#define kNoSleepCommandEnabled iokit_vendor_specific_msg(1)
#define kNoSleepCommandLockScreenRequest iokit_vendor_specific_msg(2)
// AppleNVRAM Variable name
#define IORegistrySleepSuppressionMode "IORegistryCurrentSleepMode"

// Interface
#define kNoSleepDriverClassName STR(NoSleepExtension)

// GUI
#define SHOW_UI_ALERT_KEXT_NOT_LOADED() NSRunAlertPanel(@"Oops!", @"NoSleep Kernel Extension is not loaded.", @"OK", nil, nil)

#define NOSLEEP_ID "com.protech.NoSleep"

#define NOSLEEP_HELPER_PATH "/Applications/Utilities/NoSleep.app"
#define NOSLEEP_PREFPANE_PATH "/Library/PreferencePanes/NoSleep.prefPane"

#define kNoSleepModeCurrent  0
#define kNoSleepModeAC       1
#define kNoSleepModeBattery  2

//Settings
#define NOSLEEP_SETTINGS_UPDATE_EVENTNAME "UpdateSettings"

#define NOSLEEP_SETTINGS_isBWIconEnabledID "IsBWIconEnabled"
#define NOSLEEP_SETTINGS_toLockScreenID "LockScreen"
#define NOSLEEP_SETTINGS_useDoubleClick "UseDoubleClick"
