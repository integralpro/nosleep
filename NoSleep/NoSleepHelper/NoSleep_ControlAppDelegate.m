//
//  NoSleep_ControlAppDelegate.m
//  NoSleep-Control
//
//  Created by Pavel Prokofiev on 4/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NoSleep_ControlAppDelegate.h"
#import <IOKit/IOMessage.h>
#import <NoSleep/GlobalConstants.h>
#import <NoSleep/Utilities.h>

#include <signal.h>

@implementation NoSleep_ControlAppDelegate

@synthesize window;
@synthesize statusItemMenu;

@synthesize updater;

static void handleSIGTERM(int signum) {
    if([[((NoSleep_ControlAppDelegate *)[NSApp delegate]) updater] updateInProgress]) {
        return;
    }
    
    signal(signum, SIG_DFL);
    raise(signum);
}

- (IBAction)openPreferences:(id)sender {
    BOOL ret = [[NSWorkspace sharedWorkspace] openFile:@NOSLEEP_PREFPANE_PATH];
    if(ret == NO) {
        [[NSWorkspace sharedWorkspace] openFile:
         [NSHomeDirectory() stringByAppendingPathComponent: @NOSLEEP_PREFPANE_PATH]];
    }
}

- (void)showUnloadedExtensionDialog {
    SHOW_UI_ALERT_KEXT_NOT_LOADED();
}

- (void)applicationShouldBeTerminated:(BOOL)showUI {
    if(showUI) {
        [self showUnloadedExtensionDialog];
    }

    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}

- (void)activateStatusMenu {
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    
    inactiveImage = [NSImage imageNamed:@"ZzInactive.pdf"];
    [inactiveImage setTemplate:YES];
    activeImage = [NSImage imageNamed:@"ZzActive.pdf"];
    [activeImage setTemplate:YES];
    
    if ([statusItem respondsToSelector:@selector(button)]) {
        [[statusItem button] setImage:inactiveImage];
    } else {
        [statusItem setImage:inactiveImage];
        [statusItem setHighlightMode:YES];
    }

    [statusItem setMenu:statusItemMenu];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    signal(SIGTERM, handleSIGTERM);
    //[updater setUpdateCheckInterval:60*60*24*7];
    
    noSleep = [[NoSleepInterfaceWrapper alloc] init];
    if(noSleep == nil) {
        //NSString *kextUrl = [[NSBundle mainBundle] pathForResource:@"NoSleep" ofType:@"kext"];
        noSleep = [[NoSleepInterfaceWrapper alloc] init];
        if(noSleep == nil) {
            [self applicationShouldBeTerminated:YES];
            return;
        }
    }
    [noSleep setNotificationDelegate:self];
    
    [self activateStatusMenu];
    
    //[self updateSettings];
    
    //NSString *observedObject = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
    //NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
    //[center addObserver: self
    //           selector: @selector(callbackWithNotification:)
    //               name: @NOSLEEP_SETTINGS_UPDATE_EVENTNAME
    //             object: observedObject];
    
    [self updateState:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [noSleep release];
}

- (void)dealloc {
    [super dealloc];
}

- (IBAction)updateState:(id)sender {
    if([noSleep stateForMode:kNoSleepModeCurrent]) {
        [self setEnabled:NSOnState];
    } else {
        [self setEnabled:NSOffState];
    }
}

- (NSCellStateValue)enabled {
    if ([noSleep stateForMode:kNoSleepModeCurrent]) {
        return NSOnState;
    } else {
        return NSOffState;
    }
}

- (void)setEnabled:(NSCellStateValue)value {
    NSImage *image;
    BOOL newState;
    
    if(value == NSOnState) {
        newState = YES;
        image = activeImage;
    } else {
        newState = NO;
        image = inactiveImage;
    }
    
    if(value != [self enabled]) {
        [noSleep setState:newState forMode:kNoSleepModeAC];
        [noSleep setState:newState forMode:kNoSleepModeBattery];
    }
    
    if ([statusItem respondsToSelector:@selector(button)]) {
        [[statusItem button] setImage:image];
    } else {
        [statusItem setImage:image];
    }
}

- (void)notificationReceived:(uint32_t)messageType :(void *)messageArgument
{
    switch (messageType) {
        case kIOMessageServiceIsTerminated:
            [self applicationShouldBeTerminated:NO];
            break;
        case kNoSleepCommandDisabled:
        case kNoSleepCommandEnabled:
            [self updateState:nil];
            break;
        case kNoSleepCommandLockScreenRequest:
            [self willLockScreen];
            break;
        default:
            break;
    }
}

/*
- (void)updateSettings {
    CFBooleanRef isBWIconEnabled = (CFBooleanRef)[[NSUserDefaults standardUserDefaults] valueForKey:@NOSLEEP_SETTINGS_isBWIconEnabledID];
    if(isBWIconEnabled == nil) {
        isBWIconEnabled = kCFBooleanFalse;
    }
}
*/

//- (void)callbackWithNotification:(NSNotification *)myNotification {
//    //[self updateSettings];
//}

- (void)willLockScreen {
    if(GetLockScreen()) {
        [self lockScreen:nil];
    }
}

- (IBAction)lockScreen:(id)sender {
    CFMessagePortRef portRef = CFMessagePortCreateRemote(kCFAllocatorDefault, CFSTR("com.apple.loginwindow.notify"));
    if(portRef) {
        CFMessagePortSendRequest(portRef, 0x258, 0, 0, 0, 0, 0);
        CFRelease(portRef);
    }
}

@end
