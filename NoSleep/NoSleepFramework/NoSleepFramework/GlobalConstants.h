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
// AppleNVRAM Variable name
#define IORegistrySleepSuppressionMode "IORegistryCurrentSleepMode"

// Interface
#define kNoSleepDriverClassName STR(NoSleepExtension)

// GUI
#define SHOW_UI_ALERT_KEXT_NOT_LOADED() NSRunAlertPanel(@"Oops!", @"NoSleep Kernel Extension is not loaded.", @"OK", nil, nil)

//#define LAUNCH_AGENT "com.protech.nosleep.launch.plist"
#define NOSLEEP_HELPER_PATH "/Library/Application Support/nosleep/NoSleepHelper.app"
//#define LAUNCH_AGENTS_PATH "/Library/LaunchAgents/"
//#define NOSLEEP_HELPER_IDENTIFIER @"com.protech.NoSleepHelper"