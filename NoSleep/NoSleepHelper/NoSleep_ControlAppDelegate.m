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

- (void)applicationShouldBeTerminated:(BOOL)showUI {
    if(showUI) {
        [self showUnloadedExtensionDialog];
    }
    //[statusItemImageView setImage:inactiveIcon];
    [statusItemImageView setImageState:NO];
    
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}

- (void)activateStatusMenu {
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [statusItemImageView setStatusItem:statusItem];
    
    [statusItemImageView setTarget:self];
    [statusItemImageView setMouseDownSelector:@selector(clickAction:)];
    [statusItemImageView setMouseDoubleDownSelector:@selector(doubleClickAction:)];
    
    //[statusItemImageView setImage: inactiveIcon];
    //[statusItemImageView setTitle:@"Hello all!!"];
    
    [statusItemImageView setIsBWIconEnabled:NO];
    
    NSImage *icon = [NSImage imageNamed:@"ZzActive.pdf"];
    [icon setTemplate:YES];
    [statusItemImageView setImage: icon];
    
    [statusItemImageView setInactiveImage: [NSImage imageNamed:@"ZzInactive.pdf"]];
    [statusItemImageView setActiveImage: [NSImage imageNamed:@"ZzActive.pdf"]];
    
    [statusItemImageView setImageState:NO];
    [statusItemImageView setMenu:statusItemMenu];
    
    [statusItem setView:statusItemImageView];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    signal(SIGTERM, handleSIGTERM);
    //[updater setUpdateCheckInterval:60*60*24*7];
    
    noSleep = [[NoSleepInterfaceWrapper alloc] init];
    if(noSleep == nil) {
        [self applicationShouldBeTerminated:YES];
        return;
    }
    [noSleep setNotificationDelegate:self];
    
    [self activateStatusMenu];
    
    [self updateSettings];
    
    NSString *observedObject = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
    NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
    [center addObserver: self
               selector: @selector(callbackWithNotification:)
                   name: @NOSLEEP_SETTINGS_UPDATE_EVENTNAME
                 object: observedObject];
    
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

static CFBooleanRef getUseDoubleClick() {
    return (CFBooleanRef)[[NSUserDefaults standardUserDefaults] valueForKey:@NOSLEEP_SETTINGS_useDoubleClick];
}

- (IBAction)clickAction:(id)sender {
    CFBooleanRef val = getUseDoubleClick();
    if(val == kCFBooleanFalse || val == nil) {
        [self toggleState:sender];
    }
}

- (IBAction)doubleClickAction:(id)sender {
    if(getUseDoubleClick() == kCFBooleanTrue) {
        [self toggleState:sender];
    }}

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
        [noSleep setState:NO forMode:kNoSleepModeAC];
        [noSleep setState:NO forMode:kNoSleepModeBattery];
    } else {
        [noSleep setState:YES forMode:kNoSleepModeAC];
        [noSleep setState:YES forMode:kNoSleepModeBattery];
    }
}

- (void)notificationReceived:(uint32_t)messageType :(void *)messageArgument
{
    switch (messageType) {
        case kIOMessageServiceIsTerminated:
            [self applicationShouldBeTerminated:NO];
            break;
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
    CFBooleanRef isBWIconEnabled = (CFBooleanRef)[[NSUserDefaults standardUserDefaults] valueForKey:@NOSLEEP_SETTINGS_isBWIconEnabledID];
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
