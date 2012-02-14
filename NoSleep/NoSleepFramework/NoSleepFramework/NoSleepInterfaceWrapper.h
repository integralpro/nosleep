//
//  NoSleepInterfaceWrapper.h
//  nosleep
//
//  Created by Pavel Prokofiev on 4/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <NoSleep/NoSleepInterface.h>
#import <NoSleep/NoSleepNotificationDelegate.h>

@interface NoSleepInterfaceWrapper : NSObject {
@private
    NoSleepInterfaceConnect _noSleepInterface;
    NoSleepInterestNotification _noSleepNotification;
    
    id<NoSleepNotificationDelegate> notificationDelegate;
}

@property (retain) id<NoSleepNotificationDelegate> notificationDelegate;

-(BOOL) state;
-(void) setState:(BOOL)state;

@end
