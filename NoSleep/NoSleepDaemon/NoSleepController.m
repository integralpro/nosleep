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

-(void) notificationReceived:(uint32_t)messageType :(void *)messageArgument {
    switch (messageType) {
        case kIOMessageServiceIsTerminated: {
            CFRunLoopStop(CFRunLoopGetCurrent());
            break;
        }
        case kNoSleepCommandLockScreenRequest: {
            CFMessagePortRef portRef = CFMessagePortCreateRemote(kCFAllocatorDefault, CFSTR("com.apple.loginwindow.notify"));
            if(portRef) {
                CFMessagePortSendRequest(portRef, 0x258, 0, 0, 0, 0, 0);
                CFRelease(portRef);
            }
            break;
        }
    }
}

@end
