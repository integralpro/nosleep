//
//  NoSleepInterfaceWrapper.m
//  nosleep
//
//  Created by Pavel Prokofiev on 4/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NoSleepInterfaceWrapper.h"

@implementation NoSleepInterfaceWrapper

@synthesize notificationDelegate;

static void notificationHandler(void *refCon,
                                io_service_t service,
                                uint32_t messageType,
                                void *messageArgument)
{
    NoSleepInterfaceWrapper *wrapper = (__bridge NoSleepInterfaceWrapper *)refCon;
    
    id<NoSleepNotificationDelegate> delegate = [wrapper notificationDelegate];
    if(delegate) {
        [delegate notificationReceived:messageType :messageArgument];
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        notificationDelegate = nil;
        NoSleepInterfaceService service;
        if(!NoSleep_InterfaceCreate(&service, &_noSleepInterface))
        {
            return nil;
        }
        _noSleepNotification = NoSleep_ReceiveStateChanged(service, notificationHandler, self);
    }
    
    return self;
}

- (void)dealloc
{
    NoSleep_ReleaseStateChanged(_noSleepNotification);
    NoSleep_InterfaceDestroy(_noSleepInterface);
    [super dealloc];
}

- (BOOL)stateForMode:(int)mode
{
    return NoSleep_GetSleepSuppressionMode(_noSleepInterface, mode);
}

- (void)setState:(BOOL)state forMode:(int)mode
{
    NoSleep_SetSleepSuppressionMode(_noSleepInterface, state, mode);
}

@end
