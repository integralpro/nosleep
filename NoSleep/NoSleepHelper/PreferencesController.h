//
//  PreferencesController.h
//  NoSleep
//
//  Created by Pavel Prokofiev on 11/4/15.
//
//

#import <Cocoa/Cocoa.h>

@class NSPreferencePane;

@interface PreferencesController : NSWindowController <NSWindowDelegate> {
@private
    IBOutlet NSPreferencePane *preferencePane;
    NSView *_mainView;
}

+ (nonnull PreferencesController *)create;

@end
