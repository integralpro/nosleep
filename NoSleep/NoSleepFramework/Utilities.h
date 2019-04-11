//
//  Utilities.h
//  NoSleepFramework
//
//  Created by Pavel Prokofiev on 2/24/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#ifndef NoSleepFramework_Utilities_h
#define NoSleepFramework_Utilities_h

BOOL GetLockScreenProperty(void);
void SetLockScreenProperty(BOOL value);

BOOL IsLaunchdAgentInstalled(NSBundle *application);
void InstallLaunchdAgent(NSBundle *application);
void UninstallLaunchdAgent(NSBundle *application);

void ShowAlertPanel(NSString *title, NSString *message, NSString *button);

#endif
