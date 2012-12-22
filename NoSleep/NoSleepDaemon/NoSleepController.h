//
//  NoSleepController.h
//  NoSleepDaemon
//
//  Created by Pavel Prokofiev on 12/21/12.
//  Copyright (c) 2012 Pavel Prokofiev. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <NoSleep/NoSleepInterfaceWrapper.h>

@interface NoSleepController : NSObject <NoSleepNotificationDelegate> {
@private
    NoSleepInterfaceWrapper *noSleep;
}

@end
