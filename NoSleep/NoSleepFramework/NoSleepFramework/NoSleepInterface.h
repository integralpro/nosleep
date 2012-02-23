//
//  NoSleepInterface.h
//  nosleep
//
//  Created by Pavel Prokofiev on 4/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include <IOKit/IOKitLib.h>

//io_connect_t m_connect;
typedef io_service_t NoSleepInterfaceService;
typedef io_connect_t NoSleepInterfaceConnect;
typedef io_object_t NoSleepInterestNotification;

#ifdef __cplusplus
extern "C" {
#endif
    extern bool NoSleepVerbose;
    
    NoSleepInterestNotification NoSleep_ReceiveStateChanged(NoSleepInterfaceConnect m_connect, IOServiceInterestCallback callback, void *refCon);
    void NoSleep_ReleaseStateChanged(NoSleepInterestNotification notifyObj);
    
    bool NoSleep_InterfaceCreate(NoSleepInterfaceService *service, NoSleepInterfaceConnect *connect);
    bool NoSleep_InterfaceDestroy(NoSleepInterfaceConnect connect);
    bool NoSleep_GetSleepSuppressionMode(NoSleepInterfaceConnect connect, int mode);
    bool NoSleep_SetSleepSuppressionMode(NoSleepInterfaceConnect connect, bool state, int mode);

#ifdef __cplusplus
}
#endif
