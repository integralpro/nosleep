//
//  main.c
//  NoSleepDaemon
//
//  Created by Pavel Prokofiev on 12/21/12.
//  Copyright (c) 2012 Pavel Prokofiev. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import <Cocoa/Cocoa.h>
#import "NoSleepController.h"

void exit_handler(int arg0) {
    CFRunLoopStop(CFRunLoopGetMain());
}

int main(int argc, const char * argv[])
{
    signal(SIGINT, exit_handler);
    
    printf("Starting NoSleep daemon...");
    id noSleepController = [[NoSleepController alloc] init];
    if(noSleepController == nil) {
        printf(" - BAD\n");
        printf("Couldn't connect to NoSleep kernel extension\n");
        return 1;
    }
    printf(" - OK\n");
    CFRunLoopRun();
    [noSleepController release];
    printf("NoSleep daemon stopped.\n");
    return 0;
}
