//
//  NoSleep_ControlAppDelegate.h
//  NoSleep-Control
//
//  Created by Pavel Prokofiev on 4/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <NoSleep/NoSleepInterfaceWrapper.h>

#import <Sparkle/Sparkle.h>

@interface NoSleep_ControlAppDelegate : NSObject <NSApplicationDelegate, NoSleepNotificationDelegate> {
@private
    IBOutlet NSWindow *window;
    IBOutlet NSMenu *statusItemMenu;
    
    IBOutlet SUUpdater *updater;
    
    NSStatusItem *statusItem;
    
    NoSleepInterfaceWrapper *noSleep;
    
    NSImage *inactiveImage;
    NSImage *activeImage;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSMenu *statusItemMenu;

@property (assign) IBOutlet SUUpdater *updater;

@property (assign) NSCellStateValue enabled;

- (IBAction)openPreferences:(id)sender;

- (IBAction)updateState:(id)sender;

- (void)activateStatusMenu;

- (IBAction)lockScreen:(id)sender;

@end
