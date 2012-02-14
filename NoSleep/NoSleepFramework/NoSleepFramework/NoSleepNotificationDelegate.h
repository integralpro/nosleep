//
//  NoSleepNotificationDelegate.h
//  nosleep
//
//  Created by Pavel Prokofiev on 4/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NoSleepNotificationDelegate <NSObject>
@optional

-(void) notificationReceived:(uint32_t)messageType :(void *)messageArgument;

@end
