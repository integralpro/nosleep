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

@implementation NoSleep_ControlAppDelegate

@synthesize window;
@synthesize statusItemMenu;
@synthesize statusItemImageView;

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
    [statusItemImageView setImage: icon];
    [statusItemImageView setImageState:NO];
    [statusItemImageView setMenu:statusItemMenu];
    
    [statusItem setView:statusItemImageView];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{   
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    if([args containsObject:@"--unregister-loginitem"]) {
        registerLoginItem(kLIUnregister);
    } else if([args containsObject:@"--register-loginitem"]) {
        registerLoginItem(kLIRegister);
    }
    
    //inactiveIcon = [NSImage imageNamed:@"ZzTemplate.png"];
    //activeIcon = [NSImage imageNamed:@"ZzTemplate.png"];
    icon = [NSImage imageNamed:@"ZzTemplate.png"];
    
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
    //[inactiveIcon release];
    //[activeIcon release];
    [icon release];
}

- (void)dealloc
{
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
    //if ([statusItemImageView image] == activeIcon) {
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

@end
