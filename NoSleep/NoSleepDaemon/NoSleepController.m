//
//  NoSleepController.m
//  NoSleepDaemon
//
//  Created by Pavel Prokofiev on 12/21/12.
//  Copyright (c) 2012 Pavel Prokofiev. All rights reserved.
//

#import "NoSleepController.h"
#import <IOKit/IOMessage.h>
#import <NoSleep/GlobalConstants.h>

@implementation NoSleepController

-(id)init {
    if(self = [super init]) {
        noSleep = [[NoSleepInterfaceWrapper alloc] init];
        if(noSleep) {
            [noSleep setNotificationDelegate:self];
        } else {
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    [noSleep dealloc];
    [super dealloc];
}

static BOOL testLockScreen() {
    Boolean b = false;
    Boolean ret = CFPreferencesGetAppBooleanValue(CFSTR(NOSLEEP_SETTINGS_toLockScreenID), CFSTR(NOSLEEP_ID), &b);
    if(b) {
        return ret;
    }
    return NO;
}

-(void) notificationReceived:(uint32_t)messageType :(void *)messageArgument {
    switch (messageType) {
        case kIOMessageServiceIsTerminated: {
            printf("NoSleep kext is terminated.\n");
            CFRunLoopStop(CFRunLoopGetCurrent());
            break;
        }
        case kNoSleepCommandLockScreenRequest: {
            printf("Incoming lock screen request - ");
            if(testLockScreen()) {
                printf("locked\n");
                CFMessagePortRef portRef = CFMessagePortCreateRemote(kCFAllocatorDefault, CFSTR("com.apple.loginwindow.notify"));
                if(portRef) {
                    CFMessagePortSendRequest(portRef, 0x258, 0, 0, 0, 0, 0);
                    CFRelease(portRef);
                }
            } else {
                printf("locking is not required\n");
            }
            break;
        }
    }
}

@end
