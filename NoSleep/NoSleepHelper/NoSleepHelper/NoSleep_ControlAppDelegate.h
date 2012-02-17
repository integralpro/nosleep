//
//  NoSleep_ControlAppDelegate.h
//  NoSleep-Control
//
//  Created by Pavel Prokofiev on 4/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StatusItemView.h"

#import <NoSleep/NoSleepInterfaceWrapper.h>

@interface NoSleep_ControlAppDelegate : NSObject <NSApplicationDelegate, NoSleepNotificationDelegate> {
@private
    IBOutlet NSWindow *window;
    IBOutlet NSMenu *statusItemMenu;
    IBOutlet StatusItemView *statusItemImageView;
    
    NSStatusItem *statusItem;
    //NSImage *inactiveIcon;
    //NSImage *activeIcon;
    NSImage *icon;
    
    NoSleepInterfaceWrapper *noSleep;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSMenu *statusItemMenu;
@property (assign) IBOutlet StatusItemView *statusItemImageView;

- (IBAction)openPreferences:(id)sender;

- (IBAction)updateState:(id)sender;
- (IBAction)toggleState:(id)sender;

- (void)activateStatusMenu;

@end
