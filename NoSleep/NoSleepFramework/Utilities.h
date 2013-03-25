//
//  Utilities.h
//  NoSleepFramework
//
//  Created by Pavel Prokofiev on 2/24/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#ifndef NoSleepFramework_Utilities_h
#define NoSleepFramework_Utilities_h

typedef enum {
    kLICheck    = 0,
    kLIRegister,
    kLIUnregister,
} LoginItemAction;

BOOL registerLoginItem(LoginItemAction action);

BOOL GetLockScreen();
void SetLockScreen(BOOL value);

#endif
