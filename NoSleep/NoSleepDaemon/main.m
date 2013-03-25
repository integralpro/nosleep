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
#import "Log.h"

static bool isRunning = false;

void exit_handler(int arg0) {
    if(isRunning) {
        CFRunLoopStop(CFRunLoopGetMain());
    }
}

int main(int argc, const char * argv[])
{
    int ret = 0;
    
    signal(SIGINT, exit_handler);
    signal(SIGTERM, exit_handler);
    
    openlog("NoSleepDaemon", LOG_PID, LOG_USER);
    
    log("Starting NoSleep daemon...");
    
    id noSleepController = [[NoSleepController alloc] init];
    if(noSleepController == nil) {
        log("NoSleep daemon start - FAILED");
        log("Couldn't connect to NoSleep kernel extension");
        ret = 1;
        goto exit;
    }
    log("NoSleep daemon start - OK");
    isRunning = true;
    CFRunLoopRun();
    isRunning = false;
    [noSleepController release];
    log("NoSleep daemon stopped.");
    
exit:
    closelog();
    return ret;
}
