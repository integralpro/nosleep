//
//  StatusItemView.h
//  nosleep
//
//  Created by Pavel Prokofiev on 4/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface StatusItemView : NSView <NSMenuDelegate> {
    NSStatusItem *statusItem;
    NSString *title;
    NSButtonCell *buttonCell;
    NSImage *inactiveImage;
    NSImage *activeImage;
    BOOL imageState;
    BOOL isMenuVisible;
    BOOL isEnabled;
    BOOL isBWIconEnabled;
    
    SEL mouseDownSelector;
    SEL rightMouseDownSelector;
    id target;
}

@property (retain, nonatomic) NSImage *inactiveImage;
@property (retain, nonatomic) NSImage *activeImage;
@property (retain, nonatomic) NSStatusItem *statusItem;
@property (retain, nonatomic) NSString *title;
@property (retain, nonatomic) id target;
@property (nonatomic) SEL mouseDownSelector;
@property (nonatomic) SEL rightMouseDownSelector;
@property (nonatomic) BOOL isBWIconEnabled;

- (NSImage*)image;
- (void) setImage:(NSImage*)newIcon;
- (void) setEnabled:(BOOL)newEnabled;
- (BOOL) enabled;

- (void) setImageState:(BOOL)state;
- (BOOL) imageState;

@end