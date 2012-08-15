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
@synthesize statusItemImageView;

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

- (void)applicationShouldBeTerminated {
    [self showUnloadedExtensionDialog];
    //[statusItemImageView setImage:inactiveIcon];
    [statusItemImageView setImageState:NO];
    
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}

- (void)activateStatusMenu {
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [statusItemImageView setStatusItem:statusItem];
    
    [statusItemImageView setTarget:self];
    [statusItemImageView setMouseDownSelector:@selector(toggleState:)];
    
    //[statusItemImageView setImage: inactiveIcon];
    //[statusItemImageView setTitle:@"Hello all!!"];
    
    [statusItemImageView setIsBWIconEnabled:NO];
    
    NSImage *icon = [NSImage imageNamed:@"ZzActive.pdf"];
    [icon setTemplate:YES];
    [statusItemImageView setImage: icon];
    [icon release];
    
    icon = [NSImage imageNamed:@"ZzInactive.pdf"];
    [statusItemImageView setInactiveImage: icon];
    [icon release];
    
    icon = [NSImage imageNamed:@"ZzActive.pdf"];
    [statusItemImageView setActiveImage: icon];
    [icon release];
    
    [statusItemImageView setImageState:NO];
    [statusItemImageView setMenu:statusItemMenu];
    
    [statusItem setView:statusItemImageView];
    
    [self updateSettings];
    
    NSString *observedObject = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
    NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
    [center addObserver: self
               selector: @selector(callbackWithNotification:)
                   name: @"UpdateSettings"
                 object: observedObject];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    signal(SIGTERM, handleSIGTERM);
    //[updater setUpdateCheckInterval:60*60*24*7];
    
    noSleep = [[NoSleepInterfaceWrapper alloc] init];
    if(noSleep == nil) {
        [self applicationShouldBeTerminated];
        return;
    }
    [noSleep setNotificationDelegate:self];
    
    [self activateStatusMenu];
    [self updateState:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [noSleep release];
}

- (void)dealloc
{
    [super dealloc];
}

- (IBAction)updateState:(id)sender
{
    if([noSleep stateForMode:kNoSleepModeCurrent]) {
        [statusItemImageView setImageState:YES];
    } else {
        [statusItemImageView setImageState:NO];
    }
}

- (IBAction)toggleState:(id)sender
{
    if ([statusItemImageView imageState] == YES) {
        [noSleep setState:NO forMode:kNoSleepModeCurrent];
    } else {
        [noSleep setState:YES forMode:kNoSleepModeCurrent];
    }
}

- (void)notificationReceived:(uint32_t)messageType :(void *)messageArgument
{
    switch (messageType) {
        case kNoSleepCommandDisabled:
            //[statusItemImageView setImage:inactiveIcon];
            if(messageArgument == kNoSleepModeCurrent) {
                [statusItemImageView setImageState:NO];
            }
            break;
        case kNoSleepCommandEnabled:
            //[statusItemImageView setImage:activeIcon];
            if(messageArgument == kNoSleepModeCurrent) {
                [statusItemImageView setImageState:YES];
            }
            break;
        default:
            break;
    }
}

- (void)updateSettings {
    CFBooleanRef isBWIconEnabled = (CFBooleanRef)[[NSUserDefaults standardUserDefaults] valueForKey:@"IsBWIconEnabled"];
    if(isBWIconEnabled != nil) {
        [statusItemImageView setIsBWIconEnabled:CFBooleanGetValue(isBWIconEnabled)];
    }
}

- (void)callbackWithNotification:(NSNotification *)myNotification {
    [self updateSettings];
    [statusItemImageView setNeedsDisplay:YES];
}

- (IBAction)lockScreen:(id)sender {
    CFMessagePortRef portRef = CFMessagePortCreateRemote(kCFAllocatorDefault, CFSTR("com.apple.loginwindow.notify"));
    if(portRef) {
        CFMessagePortSendRequest(portRef, 0x258, 0, 0, 0, 0, 0);
        CFRelease(portRef);
    }
}

@end
